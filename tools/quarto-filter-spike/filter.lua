--- Throwaway: map Reveal.js step syntax onto lanterne's machine surface.
---
--- Specification section 12.2 asks for this, and gives the reason: the emission
--- contract of section 3.2 is the part most likely to be wrong, and it was
--- specified before it had a caller. This is that caller. Its output is meant to
--- be read, not shipped, and it is deleted when the real extension begins.
---
--- It is a Pandoc filter rather than a Typst one, and that is a finding rather
--- than a choice. Quarto's Typst writer drops a Div's classes:
--- `::: {.incremental}` reaches the `.typ` as a bare `#block[...]`, with nothing
--- left to match on. Anything that maps Reveal's syntax has to run before that
--- writer sees it.
---
--- Two mappings, per section 14 of the specification:
---
---   `. . .`                 a step boundary, `#lanterne.pause`
---   `::: {.incremental}`    one `emit-step` per list item, revealing in turn
---
--- One traversal, in document order, because both mappings depend on how many
--- steps the slide has opened so far and a per-element filter gives no order
--- across element types.

--- The last step opened on the current slide, one based. A slide starts at 1,
--- so the first region a pause reveals belongs to step 2.
local step_floor = 1

--- Typst source, which is the only thing a filter can put in the output.
local function typst(source)
  return pandoc.RawBlock("typst", source)
end

--- True when a paragraph is Reveal's pause marker, written `. . .`.
local function is_pause(block)
  if block.t ~= "Para" then return false end
  return pandoc.utils.stringify(block.content):gsub("%s", "") == "..."
end

--- The list inside an incremental Div, or nil when it holds none.
local function list_of(div)
  for _, block in ipairs(div.content) do
    if block.t == "BulletList" or block.t == "OrderedList" then return block end
  end
  return nil
end

--- One list item, wrapped in an `emit-step` that reveals it on `step`.
---
--- The body is written as Typst source around the item's own blocks rather than
--- passed as a value. That is the first constraint the emit surface puts on a
--- caller, and it is worth stating: a filter cannot hand `emit-step` a body,
--- only bracket one, because serialising Pandoc blocks to Typst means invoking
--- the writer the filter runs before. The surface allows it only because `body`
--- is a named argument taking content, so a bracket pair is a legal call.
---
--- The wrap goes inside the item and not around it. Wrapping the item turns a
--- three-item list into three unrelated blocks, and the bullets are gone: the
--- reader sees three sentences appear one after another with no list left. This
--- is the correction the specification's section 14 mapping needs, since "per
--- list item emit-step" reads either way and only one of them keeps the list.
---
--- The cost is the one section 4.4 already records for a stepped region inside a
--- list item: the marker stays while the body is hidden, so an unrevealed item
--- shows an empty bullet. That is Reveal's own behaviour as well.
local function reveal(item, step)
  local out = { typst(string.format('#lanterne.emit-step(range: "%d-", body: [', step)) }
  for _, block in ipairs(item) do out[#out + 1] = block end
  out[#out + 1] = typst("])")
  return out
end

--- The list inside an incremental Div, each item revealed one step after the
--- last, and the list itself left standing.
local function incremental(div)
  local list = list_of(div)
  if not list then return nil end
  local items = {}
  for index, item in ipairs(list.content) do
    items[#items + 1] = reveal(item, step_floor + index)
  end
  step_floor = step_floor + #list.content
  list.content = items
  return { list }
end

function Pandoc(doc)
  local out = {}
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" then
      -- A heading opens a slide, and a slide's steps start again at one.
      step_floor = 1
      out[#out + 1] = block
    elseif is_pause(block) then
      step_floor = step_floor + 1
      out[#out + 1] = typst("#lanterne.pause")
    elseif block.t == "Div" and block.classes:includes("incremental") then
      local mapped = incremental(block)
      if mapped then
        for _, mapped_block in ipairs(mapped) do out[#out + 1] = mapped_block end
      else
        out[#out + 1] = block
      end
    else
      out[#out + 1] = block
    end
  end
  doc.blocks = out
  return doc
end
