///! Slide records become pages.
///!
///! `deck` is the document's show rule: it receives the whole body, splits it
///! into records and emits one `page(...)` call per record. A page per call
///! rather than one `set page` and a run of weak breaks, so that one page per
///! slide is structural rather than incidental, and so that a later slide able
///! to bleed or to carry a fill of its own has somewhere to say so.
///!
///! Everything a page is dressed with comes from the theme: geometry, fill,
///! fonts and sizes. A theme may also compose the page rather than only dress
///! it, by supplying renderer slots, and a page whose theme supplies none is
///! composed exactly as it was before there were any.
///!
///! Where no slot places a title, the title is not placed by this module. It is
///! the heading the author wrote, still at the head of the body the splitter
///! handed over and still inside the style wrappers it was written under, so
///! the document's own numbering, its `show heading` rule and the destination a
///! reference resolves to all keep working.
///!
///! Where a slot does place one, `split-head` takes it out with those wrappers,
///! which is the whole reason that function exists. It runs only when a slot on
///! that page would place a title, because taking one out with nowhere to put
///! it would delete it from the slide.
///!
///! Every region renders in the flow of the page body rather than in
///! `page(header: ...)`, and the per-page heading rule wraps the whole composed
///! page rather than the body region. ARCHITECTURE records why both halves of
///! that are load-bearing.
///!
///! `info` is the document's metadata, and a theme's `render-title-slide` is
///! what makes a page of it. A deck whose theme supplies none opens on its
///! first slide, as it always did.
///!
///! A slide renders one page per step rather than one page, the expansion
///! deciding how many. The dimmed state is the one place this renderer
///! compromises: Typst 0.15 has no content opacity, so a dimmed region is
///! rendered by setting its text fill rather than by fading it.

#import "../core/counters.typ": increments, rewind
#import "../core/expand.typ": expand
#import "../core/range.typ": parse-range
#import "../core/record.typ": slide-record
#import "../core/slides.typ": heading-level, slides
#import "../core/split.typ": split-head
#import "../theme/theme.typ": resolve-mode
#import "../utils/elements.typ": is-elem
#import "../utils/errors.typ": fail-enum, fail-type

// Typst's own presentation papers, measured rather than assumed: 16-9 is
// 841.89pt by 473.56pt and 4-3 is 793.7pt by 595.28pt.
#let _PAPERS = (
  "16-9": "presentation-16-9",
  "4-3": "presentation-4-3",
)

// What `set document` accepts, and the shape each key takes. As with the token
// vocabulary, this grows when something reads more; `description` and
// `keywords` are Typst's and are not read here.
#let _INFO = (
  title: (expected: "content or a string", ok: v => type(v) in (content, str)),
  author: (
    expected: "a string or an array of strings",
    ok: v => type(v) == str or (type(v) == array and v.all(name => type(name) == str)),
  ),
  date: (
    expected: "a datetime, auto or none",
    ok: v => type(v) == datetime or v == auto or v == none,
  ),
)

// A heading is set in the theme's heading font and steps up by the scale ratio
// as its level falls, so a section title reads as larger than a slide title and
// both read as larger than the body. Level 3 and below sit at the base size,
// where an in-slide heading belongs.
// `base` is the slide's own text size rather than the theme's, so a slide set
// smaller shrinks title and body together. Shrinking only the body would leave
// the title exactly as large on the slide that asked for room.
#let _heading-size(level, base, tokens) = {
  base * calc.pow(tokens.scale-ratio, calc.max(0, 3 - level))
}

// What a page's headings contribute beyond the page itself, as one `set` rule.
//
// Three rules meet here, all of them about a heading that is emitted more than
// once or that belongs to a slide the reader should not navigate to.
//
// A step page that repeats a slide already emitted carries its headings a
// second time. A numbered heading would advance the heading counter once per
// step, and that counter is hierarchical, so it cannot be put back by
// subtraction the way a figure's is; the heading is stopped from advancing it
// instead. The repeat would also list the slide again in the outline and add a
// second bookmark for it.
//
// Specification 4.7 gives the other two: a section heading is a bookmark and a
// content slide is not, and an appendix slide is excluded from the outline.
// Only what this page has to suppress is written, and a page with nothing to
// suppress carries no rule at all. Setting the permissive value would be the
// same statement to Typst and a different one to the author: the rule sits
// inside the page body, so it wins over the document's own preamble, and
// `outlined: true` on every page would quietly undo an author's
// `set heading(outlined: false)`.
// A title slide belongs to no record and is not a slide of the deck. A heading
// a theme writes into one must therefore contribute nothing: not a number, not
// an outline entry, not a bookmark. The record-driven cases cannot say that. A
// record of kind `content` yields `bookmarked: false` alone, so such a heading
// would be outlined and would advance the heading counter, and that counter is
// hierarchical, so every slide after it would take a title number one too high
// with nothing to put it back.
#let _chrome(record, repeated, body, title-slide: false) = {
  let overrides = if title-slide or repeated {
    (numbering: none, outlined: false, bookmarked: false)
  } else if record.attrs.appendix {
    (outlined: false, bookmarked: false)
  } else if record.kind != "section" {
    (bookmarked: false)
  } else {
    (:)
  }
  if overrides.len() == 0 { return body }
  [#set heading(..overrides)
    #body]
}

// A slot is called with three named arguments and returns content. Its arity
// cannot be checked, because Typst exposes nothing of a closure's parameters,
// so a theme that writes positional parameters fails here with Typst's own
// message. What can be checked is checked: a slot returning something else
// would place a value on the page and the deck would build.
//
// `none` is not something else. It says this page has no such region, which is
// what an absent slot already says, and it is what Typst returns from a
// conditional that did not fire. The `state` a slot receives carries `kind`,
// `appendix` and `step` so that a theme can vary its chrome per page, so a
// theme that hides a footer on an appendix slide is writing the case the state
// invites rather than making a type error.
#let _slot(slots, name, info, tokens, state, scope) = {
  let fn = slots.at(name, default: none)
  if fn == none { return none }
  let built = fn(info: info, tokens: tokens, state: state)
  if built != none and type(built) != content {
    fail-type(scope, name + " result", built, "content or none")
  }
  built
}

// The regions of a content page, stacked in the order they render.
//
// In flow, inside the page body, rather than in `page(header: ...)`. The text,
// paragraph and heading rules below are set inside the page body, and so is the
// per-page `set heading(...)` that suppresses a repeat: content handed to
// `page(header:)` is styled at the `page` call site and would receive none of
// them, so a title placed there would lose its font, its size, its `show
// heading` rule and its suppression rule at once. In flow is also where the
// outline, the bookmarks and a reference find it.
//
// A region with no slot behind it takes no row at all, so a theme supplying
// none composes exactly the page it composed before there were slots.
#let _regions(tokens, body: [], header: none, progress: none, footer: none) = {
  let rows = ()
  let cells = ()
  if header != none {
    rows.push(tokens.header-height)
    cells.push(header)
  }
  rows.push(1fr)
  cells.push(body)
  if progress != none {
    rows.push(auto)
    cells.push(progress)
  }
  if footer != none {
    rows.push(tokens.footer-height)
    cells.push(footer)
  }
  if cells.len() == 1 { return body }
  grid(rows: rows, row-gutter: tokens.gutter, columns: (1fr,), ..cells)
}

// A slide's title as a value a slot can place, and the body without it.
//
// The split runs only when a slot on this page would place a title: a header
// region on a content slide, or the section slot on a section slide. Taking the
// title out with nowhere to put it would delete it from the slide, and a theme
// supplying no such slot leaves the body exactly as it was, which is what keeps
// a themeless deck rendering as it always did.
//
// The predicate matches a heading at the record's own level rather than any
// heading. `split-head` takes the first child that satisfies it, which is
// weaker than the first child `slides` guarantees, so a body carrying an
// included sequence could otherwise present a heading nobody meant. A level 3
// heading written inside a slide is content.
//
// An explicit `slide(title: ...)` carries a title and no heading at all, so
// nothing is found and the record's own copy is used. That copy is a value
// rather than a heading, so no `show heading` rule reaches it, which is what
// `title-source` tells a theme.
#let _title(record, body, places-title) = {
  if not places-title or record.title == none {
    return (title: none, source: none, body: body)
  }
  // Only a title that came from a heading may be taken out of the body. A title
  // passed to `slide(...)` is an argument, and that slide's body is never split,
  // so it may legitimately carry a heading at the record's own level: taking
  // that heading would discard the argument the author wrote and delete the
  // heading from the body in the same move.
  if record.title-source != "heading" {
    return (title: record.title, source: record.title-source, body: body)
  }
  let cut = split-head(
    body,
    node => is-elem(node, heading) and heading-level(node) == record.level,
  )
  // The heading is at the head of the body by construction, since that is what
  // opened the slide. Not finding it means something upstream rebuilt the body
  // without it, so the record's own copy is placed rather than nothing.
  if cut.found {
    return (title: cut.head, source: "heading", body: cut.rest)
  }
  (title: record.title, source: "value", body: body)
}

#let _slide-page(
  record,
  body,
  tokens,
  paper,
  info: (:),
  mode: "light",
  step: (index: 1, total: 1),
  prelude: [],
  repeated: false,
  title-slide: false,
  scope: "deck",
) = {
  // `smaller` is per slide rather than per deck, so it is read here rather than
  // folded into the theme.
  let size = if record.attrs.smaller {
    tokens.size-base / tokens.scale-ratio
  } else {
    tokens.size-base
  }
  let slots = tokens.slots
  let section-slot = if record.kind == "section" {
    slots.at("render-section-slide", default: none)
  } else {
    none
  }
  let header-slot = if record.kind == "section" { none } else { slots.at("render-header", default: none) }
  let cut = _title(record, body, header-slot != none or section-slot != none)
  let state = (
    kind: record.kind,
    title: cut.title,
    title-source: cut.source,
    level: record.level,
    appendix: record.attrs.appendix,
    body: cut.body,
    step: step,
    mode: mode,
  )
  page(paper: paper, fill: tokens.bg, margin: tokens.margin, {
    set text(font: tokens.font-base, size: size, fill: tokens.fg)
    set par(leading: tokens.leading)
    show heading: it => block(text(
      font: tokens.font-heading,
      weight: tokens.weight-heading,
      size: _heading-size(it.level, size, tokens),
      it.body,
    ))
    // The counter shifts for this step, before anything is laid out and
    // outside the composition below, so that a step numbers what the slide's
    // first step numbered. They render as nothing and reserve no space.
    prelude
    // Where no slot composes the page, the title is not placed here. It is the
    // heading the author wrote, still at the head of the body and still inside
    // the wrappers it was written under, which is what keeps the document's own
    // numbering, `show` rules and reference destinations working on it.
    //
    // Where a slot does compose the page, the title is still inside those
    // wrappers: `split-head` takes it out with them, which is the whole reason
    // that function exists.
    //
    // A section slide is a divider, so what it carries sits in the middle of
    // the page rather than at the top of it, unless a theme says otherwise.
    let composed-or-none = if title-slide {
      // A title slide is a page of its own, not a slide of the deck dressed
      // like the rest. A theme that supplies a header and a footer draws them
      // on its slides; drawing them over its own title page as well would put
      // deck chrome on the one page that is not a deck slide, and the regions
      // would receive a `state` describing no slide at all.
      body
    } else if section-slot != none {
      _slot(slots, "render-section-slide", info, tokens, state, scope)
    } else if record.kind == "section" {
      align(center + horizon, cut.body)
    } else {
      _regions(
        tokens,
        body: cut.body,
        header: _slot(slots, "render-header", info, tokens, state, scope),
        progress: _slot(slots, "render-progress", info, tokens, state, scope),
        footer: _slot(slots, "render-footer", info, tokens, state, scope),
      )
    }
    // A composing slot that returns `none` composes an empty page, since it
    // was asked what this page is and answered nothing.
    let composed = if composed-or-none == none { [] } else { composed-or-none }
    // The whole composed page, not the body region alone. A title moved into a
    // header region beside this rule would escape all three suppressions: the
    // heading counter would advance once per step, the outline would list the
    // slide once per step, and the PDF would gain a bookmark per step.
    _chrome(record, repeated, composed, title-slide: title-slide)
  })
}

/// Render a document body as slides.
///
/// It is written as the document's show rule.
///
/// One pass over the body's top level children, splitting at anything that
/// opens a slide:
///
/// | Boundary | Opens |
/// | --- | --- |
/// | A heading at `slide-level` | A content slide, titled by that heading. |
/// | A heading below `slide-level` | A section slide, whose content is centred on the page. |
/// | A heading above `slide-level` | Nothing: it is ordinary content on the slide it sits in. |
/// | `#pagebreak()` | An untitled slide, even when nothing follows it. |
/// | `slide(...)` | A slide complete in itself; what follows opens another. |
///
/// Content before the first boundary is an implicit untitled slide, and is
/// dropped when nothing in it puts a mark on the page.
///
/// Only top level children are examined, so a heading nested inside a block, a
/// grid cell or a list item never splits the deck. The same limit applies to
/// `slide-options`, which has to be a top level child of the slide it
/// configures.
///
/// A heading that opens a slide stays where it was written, at the head of that
/// slide's body, rather than being lifted out and re-emitted. That is what
/// keeps `set heading(numbering: ...)`, a `show heading` rule and a reference to
/// a labelled heading all working on it.
///
/// A slide renders one page per step rather than one page. The step count comes
/// from the region and pause markers a slide's body carries, from any
/// `context-slide` callback's own `steps` option, and is at least one.
/// @category deck
/// @stability experimental
/// @param body The document, passed by the show rule.
/// @param theme A token dictionary from `theme-tokens` or `theme-merge`, or a light and dark pair written as `(light: ..., dark: ...)` with a token dictionary in each half. `none` takes the canonical defaults.
/// @param theme-mode Which half of a pair to render, `"light"` or `"dark"`. A theme that is a single token set has one answer, so naming a mode against one is not an error. Both halves of a pair are validated whichever is rendered.
/// @param aspect-ratio The page shape, `"16-9"` or `"4-3"`. These are Typst's own presentation papers: 841.89pt by 473.56pt, and 793.7pt by 595.28pt.
/// @param slide-level The heading level that opens a slide, per `slides`. `0` disables heading splitting and leaves only the explicit breaks.
/// @param handout `false` renders every step. `true` collapses each slide to its final step, which is what a handout wants. A range collapses it to the steps the range selects, still one page per selected step.
/// @param registry A container registry from `register-container`, for a step written inside a container of your own. `none` reads the built in registry.
/// @param info Document metadata, passed to `set document`. It takes `title`, `author` and `date`, and rejects an unknown key rather than passing it through: the vocabulary carries only what something reads.
/// @returns content
/// @examples-static
/// ```typst
/// #show: deck.with(theme: theme-tokens(), aspect-ratio: "16-9", slide-level: 2)
///
/// = A section
///
/// == A slide
///
/// Its body.
/// ```
#let deck(
  body,
  theme: none,
  theme-mode: "light",
  aspect-ratio: "16-9",
  slide-level: 2,
  handout: false,
  registry: none,
  info: (:),
) = {
  let scope = "deck"
  if aspect-ratio not in _PAPERS {
    fail-enum(scope, "aspect-ratio", aspect-ratio, _PAPERS.keys())
  }
  if type(info) != dictionary {
    fail-type(scope, "info", info, "a dictionary of document metadata")
  }
  for (name, value) in info {
    let spec = _INFO.at(name, default: none)
    if spec == none {
      fail-enum(scope, "info key", name, _INFO.keys())
    }
    if not (spec.ok)(value) {
      fail-type(scope, "info." + name, value, spec.expected)
    }
  }
  if type(registry) != dictionary and registry != none {
    fail-type(scope, "registry", registry, "a registry from register-container, or none")
  }
  // false is every step, true is the final one, and anything else is a range
  // read by the same parser a step range uses, so one set of messages covers
  // both.
  let keep = if handout == false {
    none
  } else if handout == true {
    "final"
  } else {
    parse-range(handout, scope, name: "handout")
  }
  // The theme is validated by the one function that validates a theme, so a
  // token rejected here reads the same as one rejected where it was written.
  // That one function also reads the mode, takes the defaults and refuses a
  // theme of the wrong shape, so the shape of a theme is stated once. A guard
  // here would be a second statement of it, and the two would drift.
  //
  // It reports the mode it resolved as well as the tokens, since a theme with
  // no halves renders light whatever mode was asked for. Nothing reads that
  // mode until the renderer slots land, so nothing takes it here yet.
  let resolved = resolve-mode(theme, theme-mode, scope)
  let tokens = resolved.tokens
  // The split validates `body` and `slide-level` under this scope, so the
  // message names the function the author called and there is one copy of it.
  let records = slides(body, slide-level: slide-level, scope: scope)

  // The dimmed state is built here, because this is the layer that has the
  // tokens. Typst 0.15 has no content opacity, so dimming sets the text fill:
  // an image, an explicit fill and a stroke inside a dimmed region do not dim,
  // which is documented at the export rather than faked with an overlay.
  let dim-region = region => text(
    fill: tokens.fg.transparentize(100% - tokens.dim-opacity),
    region,
  )
  // Metadata is set before any page is opened, because Typst resolves the
  // document's own properties once and before it lays anything out.
  set document(..info)

  // A title slide belongs to no record: it is what a theme makes of the deck's
  // own metadata, so it is emitted only when a theme says how. `deck` emitted
  // none before there were slots, which is why nothing regresses. The slot
  // decides what an empty `info` means rather than the renderer deciding for
  // it.
  if "render-title-slide" in tokens.slots {
    _slide-page(
      slide-record([], attrs: (appendix: false)),
      _slot(tokens.slots, "render-title-slide", info, tokens, (
        kind: "content",
        title: none,
        title-source: none,
        level: none,
        appendix: false,
        body: [],
        step: (index: 1, total: 1),
        mode: resolved.mode,
      ), scope),
      tokens,
      _PAPERS.at(aspect-ratio),
      info: info,
      mode: resolved.mode,
      title-slide: true,
      scope: scope,
    )
  }

  for record in records {
    let expanded = expand(
      record.body,
      dim-region,
      steps: record.attrs.steps,
      keep: keep,
      registry: registry,
      scope: scope,
    )
    // A slide numbers what its first step numbers, so every later step rewinds
    // the counters by what the whole slide body advances. The count is read
    // from the body rather than from the counters themselves: capturing a
    // counter and putting the value back does not converge across a deck, and
    // renders wrong numbers rather than failing. See src/core/counters.typ.
    //
    // A slide of one step needs none of it, which is every slide of a static
    // deck and every slide under `handout: true`.
    let counts = if expanded.steps.len() > 1 { increments(record.body) } else { none }
    for (index, part) in expanded.steps.enumerate() {
      _slide-page(
        record,
        part.body,
        tokens,
        _PAPERS.at(aspect-ratio),
        info: info,
        mode: resolved.mode,
        // The step's place in the slide's whole step space, which is what a
        // range is written against, rather than its place among the pages this
        // render happens to emit. A handout therefore reports the step it kept.
        step: (index: part.index, total: expanded.total),
        prelude: if index == 0 or counts == none { [] } else { rewind(counts) },
        repeated: index > 0,
        scope: scope,
      )
    }
  }
}
