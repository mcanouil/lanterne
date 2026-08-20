#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end
local DIR = script_dir()
local DEFAULT_ROOT = DIR .. "/../.."
package.path = DIR .. "/?.lua;" .. package.path

local util = require("util")
local parser = require("parser")
local render = require("render")
local resolve = require("resolve")

-- Vendored from gribouille, per specification section 11, and reduced to what
-- lanterne has. Six modules of the original are absent and are not coming back
-- unless the thing they read exists here:
--
--   deps.lua        reads src/deps.typ. Lanterne has no runtime dependency and
--                   forbids a @preview import under src/, so there is nothing
--                   to collect and docs/_scripts/pre-render.sh already writes
--                   _variables.yml.
--   changelog.lua   writes changelog.qmd, which pre-render.sh already writes.
--   examples.lua    enforces a gallery. Lanterne has no gallery.
--   scale_keys.lua  } generate reference tables out of gribouille's own
--   theme_keys.lua  } dictionaries. A lanterne equivalent for the theme token
--   stat_info.lua   } vocabulary belongs with M6, when that vocabulary is
--                   complete rather than 10 names of 28.
--
-- The sidebar generator is gone as well. This site carries one docked sidebar
-- rather than one per section, so the reference is navigated with Quarto's own
-- `auto` glob in docs/_quarto.yml and no YAML is generated for it.
--
-- The generator therefore writes the reference pages, and nothing else.

local USAGE = [[
Usage: tools/typstdoc/main.lua [options]

Options:
  --root <dir>        Repository root (default: two levels above this script). Prefixes all path defaults.
  --src <dir>         Source directory to scan (default: <root>/src)
  --lib <file>        Library entry point (default: <root>/lib.typ)
  --out <dir>         Output directory for reference pages (default: <root>/docs/reference)
  --strict            Treat unresolved @refs as errors
  --check             Parse and validate without writing
  --help              Show this help and exit
]]

local VALUE_FLAGS = {
  ["--root"] = "root",
  ["--src"] = "src",
  ["--lib"] = "lib",
  ["--out"] = "out",
}

local BOOL_FLAGS = {
  ["--strict"] = "strict",
  ["--check"] = "check",
}

local function parse_args(argv)
  local opts = { root = DEFAULT_ROOT, strict = false, check = false }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--help" or a == "-h" then
      io.write(USAGE); os.exit(0)
    elseif BOOL_FLAGS[a] then
      opts[BOOL_FLAGS[a]] = true; i = i + 1
    elseif VALUE_FLAGS[a] then
      local value = argv[i + 1]
      if not value then util.die("missing value for " .. a) end
      opts[VALUE_FLAGS[a]] = value; i = i + 2
    else
      util.die("unknown argument: " .. a)
    end
  end
  opts.src = opts.src or (opts.root .. "/src")
  opts.lib = opts.lib or (opts.root .. "/lib.typ")
  opts.out = opts.out or (opts.root .. "/docs/reference")
  return opts
end

-- Every file is parsed, so a malformed tag anywhere is an error, and only the
-- names `lib.typ` re-exports are carried forward to be rendered. What that file
-- does not name is internal on purpose, and a reference that listed it would
-- promise a surface the package does not offer.
local function parse_sources(src_dir, lib_info)
  local files = util.find_typ_files(src_dir)
  local exported = {}
  local modules = {}
  for _, file in ipairs(files) do
    local parsed = parser.parse_file(file)
    if parsed.module then
      modules[#modules + 1] = {
        file = parsed.file,
        category = nil,
        description = parsed.module.lines,
      }
    end
    for _, fn in ipairs(parsed.functions) do
      parser.validate_function(fn, lib_info)
      if lib_info.exports[fn.name] then
        exported[#exported + 1] = fn
      end
    end
  end
  return files, exported, modules
end

local function report_check(files, all_functions)
  util.log_info(string.format(
    "parsed %d function(s) across %d file(s); check OK",
    #all_functions, #files))
end

local function write_reference(opts, all_functions, modules, lib_info)
  local index = resolve.build_index(all_functions, lib_info)

  util.remove_generated_files(opts.out, "*.qmd")
  util.make_dir(opts.out)

  local written = 0
  for _, fn in ipairs(all_functions) do
    if fn.doc and fn.doc.category then
      local body, rel_path = render.render_function(fn, index, { strict = opts.strict })
      util.write_file(opts.out .. "/" .. rel_path, body)
      written = written + 1
    end
  end

  for _, cat in ipairs(lib_info.category_order) do
    local body, rel_path = render.render_category_index(cat, all_functions, modules, index, opts.strict)
    util.write_file(opts.out .. "/" .. rel_path, body)
  end

  local top_body, top_path = render.render_top_index(lib_info.category_order, all_functions, index, opts.strict)
  util.write_file(opts.out .. "/" .. top_path, top_body)

  return written
end

local function main(argv)
  local ok, opts = pcall(parse_args, argv)
  if not ok then util.log_err(tostring(opts)); io.write(USAGE); os.exit(2) end

  local lib_info = parser.parse_lib(opts.lib)
  local files, all_functions, modules = parse_sources(opts.src, lib_info)

  if opts.check then
    report_check(files, all_functions)
    return 0
  end

  local written = write_reference(opts, all_functions, modules, lib_info)
  util.log_info(string.format("wrote %d function page(s) under %s", written, opts.out))
  return 0
end

local ok, err = pcall(main, arg or {})
if not ok then
  util.log_err(tostring(err))
  os.exit(1)
end
