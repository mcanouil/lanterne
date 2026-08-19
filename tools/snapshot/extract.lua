-- What the snapshot harness renders.
--
-- Vendored from gribouille and reduced. There, a source is one plot and one
-- golden, and half of them are `/// @examples` fences lifted out of `src/` and
-- wrapped in a page of automatic size. Neither half transfers:
--
--   A deck is a fixed-size, multi-page document. Its pages are the thing worth
--   pinning, so one source yields as many goldens as it has pages, and there is
--   no wrapper to write: a deck is already a document.
--
--   Lanterne's doc comments use `@examples-static`, which shows code without
--   compiling it, so there is nothing in `src/` to extract. The fences that
--   compile need a Typst engine the documentation site does not have.
--
-- What is left is the decks under `examples/`, which is where the visual
-- surface lives until themes and layouts arrive with milestones of their own.

local util = require("util")

local M = {}

local function make_matcher(only)
  if not only then return function() return true end end
  return function(key) return key:find(only, 1, true) ~= nil end
end

-- One entry per deck. `pages` is not known until the deck compiles, so a source
-- names the directory its pages land in rather than a single file.
function M.collect(opts)
  assert(opts.root, "extract.collect: root required")
  assert(opts.build_root, "extract.collect: build_root required")
  assert(opts.golden_root, "extract.collect: golden_root required")

  local matches = make_matcher(opts.only)
  local sources = {}
  for _, file in ipairs(util.find_typ_files(opts.root .. "/examples")) do
    local name = file:match("([^/]+)%.typ$")
    local key = "examples/" .. name
    if matches(key) then
      sources[#sources + 1] = {
        key = key,
        name = name,
        group = "examples",
        src_typ = file,
        golden_dir = opts.golden_root .. "/examples",
        png_dir = opts.build_root .. "/png/examples",
      }
    end
  end
  table.sort(sources, function(a, b) return a.key < b.key end)
  return sources
end

return M
