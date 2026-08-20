///! A document body becomes slide records.
///!
///! One pass of `split-at` does the work, with a predicate matching the three
///! things that open a slide: a heading at or below the deck's slide level, an
///! explicit `#pagebreak()`, and an explicit `slide(...)`. The boundary that
///! opened a segment decides what kind of slide it is, which is why the split
///! has to hand the boundary back rather than drop it.
///!
///! A heading opening a slide stays where it was written, at the head of the
///! slide's body, rather than being lifted out and re-emitted by the renderer.
///! Lifting it out takes it away from the style wrappers it was written under,
///! and with them the document's own numbering, its `show heading` rule and the
///! named destination a reference resolves to. The record's `title`, `level` and
///! `label` therefore describe the heading for whatever reads a record; the body
///! is what renders.
///!
///! Only top level children are examined, so a heading nested inside a block, a
///! grid cell or a list item never splits. That is specified rather than worked
///! around: a heading inside a container is content the author put there, and
///! cutting the container in half to honour it would change what they wrote.
///!
///! The same limit applies to the option marker, which has to be a top level
///! child of the segment it configures.
///!
///! One shape is not reachable. A `set heading(offset: ...)` rule lives in the
///! style wrapper rather than in the heading, and Typst exposes no way to read a
///! wrapper's rules, so a heading under one is split at the level it was written
///! at rather than at the level it renders at. Write the level you mean, or set
///! `slide-level` to match the offset. An offset passed to `heading` itself is
///! read and counted, since that one is a field.

#import "marker.typ": MARKER-APPENDIX, MARKER-SLIDE, MARKER-SLIDE-OPTIONS, is-marker, marker
#import "record.typ": check-attrs, slide-record
#import "split.typ": is-blank, split-at
#import "walk.typ": collect
#import "../utils/elements.typ": SEQUENCE, SPACE, STYLED, is-elem
#import "../utils/errors.typ": fail, fail-type

// The kind of marker `node` is, or none when it is not one.
#let _kind(node) = {
  if is-marker(node) { node.value.kind } else { none }
}

// A heading's level, which is written under three names and reported under
// whichever the author reached for. `heading(level: 2)` carries `level`; markup
// carries `depth`; `heading(offset: 1)` carries `offset` and neither of the
// others, since the depth it is added to is the default of 1. A splitter reading
// one name alone fails on the decks that use another.
//
// Called on headings only, which is what makes the default of 1 sound.
#let _heading-level(node) = {
  let fields = node.fields()
  let level = fields.at("level", default: none)
  if level != none { return level }
  fields.at("depth", default: 1) + fields.at("offset", default: 0)
}

// What opens a slide. A slide level of 0 disables heading splitting, and a
// heading's level is at least 1, so the comparison covers it without a case of
// its own.
#let _is-boundary(node, slide-level) = {
  if _kind(node) == MARKER-SLIDE { return true }
  // The appendix marker opens a slide it does not fill: what follows it is
  // either a heading, which opens a slide of its own, or nothing. Treating it
  // as a boundary is what lets the splitter consume it, since a marker left in
  // a segment would render as nothing and flag no slide at all.
  if _kind(node) == MARKER-APPENDIX { return true }
  if is-elem(node, pagebreak) { return true }
  if not is-elem(node, heading) { return false }
  _heading-level(node) <= slide-level
}

// The top level children of a segment, with style wrappers peeled and nested
// sequences flattened. This is the surface the option marker has to sit on, and
// `_without-options` below removes from exactly the same surface, so what is
// found is what is removed.
#let _top-children(node) = {
  if is-elem(node, STYLED) { return _top-children(node.child) }
  if is-elem(node, SEQUENCE) { return node.children.map(_top-children).flatten() }
  (node,)
}

// The segment with its option markers removed, wrappers and labels intact. Only
// called for a segment known to carry one, so a segment that uses no option is
// handed back as the identical value rather than a rebuilt copy of it.
#let _without-options(node) = {
  if is-elem(node, STYLED) {
    let element-label = node.fields().at("label", default: none)
    let rebuilt = STYLED(_without-options(node.child), node.styles)
    return if element-label == none { rebuilt } else { [#rebuilt#element-label] }
  }
  if is-elem(node, SEQUENCE) {
    let element-label = node.fields().at("label", default: none)
    let rebuilt = node.children.map(_without-options).sum(default: [])
    return if element-label == none { rebuilt } else { [#rebuilt#element-label] }
  }
  if _kind(node) == MARKER-SLIDE-OPTIONS { return [] }
  node
}

// The options a segment carries, and the segment without them.
//
// The specification places the marker immediately after the heading, so nothing
// but the heading itself may come before it. A marker further down, or a second
// one, is an error rather than the option set nobody notices being ignored: a
// marker no consumer matches renders as nothing, so the deck would build and be
// wrong.
#let _take-options(segment, scope) = {
  let children = _top-children(segment)
  let found = children.filter(child => _kind(child) == MARKER-SLIDE-OPTIONS)
  if found.len() == 0 { return (attrs: (:), body: segment) }
  if found.len() > 1 {
    fail(
      scope,
      "a slide carries " + str(found.len()) + " slide-options markers",
      hint: "Write one slide-options call per slide, immediately after its heading.",
    )
  }
  let index = children.position(child => _kind(child) == MARKER-SLIDE-OPTIONS)
  let before = child => not (is-blank(child) or is-elem(child, heading))
  if children.slice(0, index).any(before) {
    fail(
      scope,
      "slide-options must come before the slide's content",
      hint: "Move the slide-options call to just after the heading.",
    )
  }
  (attrs: found.first().value.payload, body: _without-options(segment))
}

// The appendix switch, filled into a slide's own options. An option written on
// the slide wins, since it is the more specific statement, which is what makes
// `slide-options(appendix: false)` an escape from the switch.
#let _in-appendix(attrs, in-appendix) = {
  if in-appendix and "appendix" not in attrs { attrs + (appendix: true) } else { attrs }
}

// The record for one segment, given the boundary that opened it. The heading
// stays in the body, where the rules in force over it still reach it, so the
// title read from it here describes the slide rather than replacing what
// renders.
#let _record(boundary, segment, slide-level, scope, in-appendix) = {
  let taken = _take-options(segment, scope)
  // The switch fills the option, so the machine surface receives an ordinary
  // slide option and a slide can still be marked one at a time. An option
  // written on the slide wins, since it is the more specific statement.
  let attrs = _in-appendix(taken.attrs, in-appendix)
  if boundary == none or not is-elem(boundary, heading) {
    return slide-record(taken.body, attrs: attrs)
  }
  let level = _heading-level(boundary)
  slide-record(
    taken.body,
    kind: if level < slide-level { "section" } else { "content" },
    title: boundary.body,
    level: level,
    label: boundary.fields().at("label", default: none),
    attrs: attrs,
  )
}

/// Split `body` into slide records, following specification section 4.1.
///
/// A heading below `slide-level` opens a section slide, one at `slide-level`
/// opens a content slide titled by it, and one above it is ordinary content. A
/// `slide-level` of 0 disables heading splitting, leaving only the explicit
/// breaks.
///
/// Content before the first boundary is an implicit untitled slide, and is
/// dropped when nothing in it puts a mark on the page. An explicit
/// `#pagebreak()` opens a slide even when nothing follows it, because it is
/// what the author asked for.
///
/// `scope` names the caller in any message this raises, since a deck reaches
/// this through `deck` and an author told to fix `slides` has no such call to
/// find. It is the arrangement `check-token` and `check-attrs` already use.
/// @category core
/// @returns array
#let slides(body, slide-level: 2, scope: "slides") = {
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  if type(slide-level) != int or slide-level < 0 {
    fail-type(scope, "slide-level", slide-level, "a non-negative integer")
  }

  // An appendix marker the split cannot reach is refused, exactly as a pause in
  // the same position is: the marker renders as nothing, so a deck written with
  // one inside a block would build with no appendix and no warning.
  let reachable = collect(body, node => _kind(node) == MARKER-APPENDIX).len()

  let records = ()
  let in-appendix = false
  let opened = 0
  // A heading is kept where it was found, at the head of the segment it opened,
  // so that the wrappers it was written under still govern it. A page break and
  // a slide marker are consumed instead: the first would open a page inside the
  // page it opened, and the second renders as nothing.
  let parts = split-at(
    body,
    node => _is-boundary(node, slide-level),
    keep: node => is-elem(node, heading),
  )
  for part in parts {
    let boundary = part.boundary
    // An explicit slide is complete in itself, so it is emitted before the
    // segment it opened, which is the content written after it and belongs to a
    // slide of its own.
    if _kind(boundary) == MARKER-APPENDIX {
      // Every slide from here on is an appendix slide. The marker itself opens
      // nothing: the segment it holds is whatever sits between it and the next
      // heading, which is dropped when it is blank.
      in-appendix = true
      opened += 1
    }
    if _kind(boundary) == MARKER-SLIDE {
      let given = boundary.value.payload
      // Its options are its arguments. A marker inside its body has no heading
      // to follow and would be read by nobody, so it is refused rather than
      // dropped.
      let inside = _take-options(given.body, scope)
      if inside.attrs.len() > 0 {
        fail(
          scope,
          "slide-options was written inside an explicit slide",
          hint: "Pass the option to slide itself, as slide(smaller: true)[...].",
        )
      }
      records.push(slide-record(
        given.body,
        title: given.title,
        // A slide of the author's own sits where the deck's slides sit, so a
        // title with no level takes the deck's. A deck that splits on no heading
        // at all still has to give it a level a heading could be written at.
        level: if given.title != none and given.level == none {
          calc.max(slide-level, 1)
        } else {
          given.level
        },
        // An explicit slide written after the marker is an appendix slide as
        // much as one a heading opened, so the switch reaches it here too.
        attrs: _in-appendix(given.attrs, in-appendix),
      ))
    }
    // A boundary the author wrote opens a slide whatever is under it: a
    // title-only slide is legitimate, and so is a page break with nothing after
    // it. Only the segments no boundary opened are dropped when blank, namely
    // the lead-in and whatever follows an explicit slide.
    let opened-by-author = is-elem(boundary, heading) or is-elem(boundary, pagebreak)
    if not opened-by-author and is-blank(part.body) { continue }
    records.push(_record(boundary, part.body, slide-level, scope, in-appendix))
  }

  if reachable > opened {
    fail(
      scope,
      "an appendix marker sits inside an element, where the split cannot reach it",
      hint: "Write #appendix as a top level child of the document body.",
    )
  }
  // A deck has one appendix. A second marker would open a slide and change
  // nothing, which is the silent no-op this package refuses everywhere else.
  if opened > 1 {
    fail(
      scope,
      "a deck carries " + str(opened) + " appendix markers",
      hint: "Write one #appendix, at the point the appendix opens.",
    )
  }

  records
}

/// A slide written out in full, rather than opened by a heading.
///
/// It is complete in itself and is not merged with the content around it: what
/// precedes it closes, and what follows it opens a slide of its own.
///
/// Options are validated here, where they are written, because a mistyped one
/// would otherwise render as nothing at all. A second positional argument is
/// rejected, as is a `slide-options` call inside the body: an explicit slide's
/// options are its own arguments, so write `slide(smaller: true)[...]`.
/// @category deck
/// @stability experimental
/// @param body The slide's content, as the one positional argument.
/// @param title The slide's title, or `none` for an untitled slide.
/// @param level The heading level the title stands at. It defaults to the deck's slide level when a title is given, since the arguments are read here and the deck's level is only known once the body is split.
/// @param ..attrs Slide options, named only, validated as for `slide-options`.
/// @returns content
/// @examples-static
/// ```typst
/// #slide(title: [A slide of one's own])[
///   An explicit slide is complete in itself.
/// ]
/// ```
#let slide(body, title: none, level: none, ..attrs) = {
  let scope = "slide"
  if attrs.pos().len() > 0 {
    fail(
      scope,
      "takes one positional argument, its body; got " + repr(attrs.pos()),
      hint: "Write slide(title: [T])[body].",
    )
  }
  check-attrs(attrs.named(), scope)
  marker(
    MARKER-SLIDE,
    payload: (body: body, title: title, level: level, attrs: attrs.named()),
  )
}

/// The point a deck's appendix opens at, written `#appendix`.
///
/// Every slide after it is an appendix slide, so it is written once rather than
/// marked on each: an appendix is the tail of a deck. The splitter consumes the
/// marker and sets the `appendix` slide option on each later record, so the
/// machine surface receives an ordinary option and a single slide can still be
/// marked on its own.
///
/// It has to be a top level child of the document body. One written inside a
/// block is refused rather than rendering as nothing and flagging no slide, and
/// one written inside a `context` block cannot be refused, since nothing there
/// is reachable: the deck builds with no appendix, exactly as `#pause` in that
/// position is lost.
///
/// A second marker is an error. A deck has one appendix, and a marker that
/// changed nothing would be the silent no-op this package refuses elsewhere.
/// @category deck
/// @stability experimental
#let appendix = marker(MARKER-APPENDIX)

/// Options for the slide a heading opened, written immediately after it.
///
/// The marker is consumed by the splitter and never rendered. It has to be a
/// top level child of its slide, and nothing but the slide's own heading may
/// precede it, so one written inside a block is not found. Two markers on one
/// slide are an error rather than one of them silently winning.
///
/// Three options today. `appendix` excludes the slide from the outline and
/// from the PDF bookmarks. `smaller` sets the slide's text one step down the
/// theme's `scale-ratio`, title and body together. `steps` raises the slide's
/// step count to at least the given number, which a `context-slide` callback
/// needs when it wants more steps than the rest of the body advertises.
///
/// The vocabulary grows with the code that reads an option, so `layout`
/// arrives with the layout system rather than shipping a name that means
/// nothing yet.
/// @category deck
/// @stability experimental
/// @param ..attrs The options, named only.
/// @returns content
/// @examples-static
/// ```typst
/// == Set smaller
///
/// #slide-options(smaller: true)
/// ```
#let slide-options(..attrs) = {
  let scope = "slide-options"
  if attrs.pos().len() > 0 {
    fail(
      scope,
      "takes named arguments only; got " + repr(attrs.pos()),
      hint: "Write slide-options(smaller: true).",
    )
  }
  check-attrs(attrs.named(), scope)
  marker(MARKER-SLIDE-OPTIONS, payload: attrs.named())
}
