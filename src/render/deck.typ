///! Slide records become pages.
///!
///! `deck` is the document's show rule: it receives the whole body, splits it
///! into records and emits one `page(...)` call per record. A page per call
///! rather than one `set page` and a run of weak breaks, so that one page per
///! slide is structural rather than incidental, and so that a later slide able
///! to bleed or to carry a fill of its own has somewhere to say so.
///!
///! Everything a page is dressed with comes from the theme: geometry, fill,
///! fonts and sizes. There is no layout system and no chrome here, so a slide
///! is its title and its body, and nothing sits in a header or a footer yet.
///!
///! A slide's title is not placed by this module. It is the heading the author
///! wrote, still at the head of the body the splitter handed over and still
///! inside the style wrappers it was written under, so the document's own
///! numbering, its `show heading` rule and the destination a reference resolves
///! to all keep working. The record's `title` and `level` say what the slide is
///! called, for the chrome that will read them.
///!
///! `info` sets the document's metadata and nothing else. A title slide is a
///! renderer's job, and the renderer slots arrive with the theming milestone,
///! so emitting a plain one here would be code that milestone replaces rather
///! than extends.
///!
///! A slide renders one page per step rather than one page, the expansion
///! deciding how many. The dimmed state is the one place this renderer
///! compromises: Typst 0.15 has no content opacity, so a dimmed region is
///! rendered by setting its text fill rather than by fading it.

#import "../core/counters.typ": increments, rewind
#import "../core/expand.typ": expand
#import "../core/range.typ": parse-range
#import "../core/slides.typ": slides
#import "../theme/theme.typ": resolve-mode
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
#let _chrome(record, repeated, body) = {
  let overrides = if repeated {
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

#let _slide-page(record, body, tokens, paper, prelude: [], repeated: false) = {
  // `smaller` is per slide rather than per deck, so it is read here rather than
  // folded into the theme.
  let size = if record.attrs.smaller {
    tokens.size-base / tokens.scale-ratio
  } else {
    tokens.size-base
  }
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
    // outside the alignment below, so that a step numbers what the slide's
    // first step numbered. They render as nothing and reserve no space.
    prelude
    // The title is not placed here. It is the heading the author wrote, still
    // at the head of the body and still inside the wrappers it was written
    // under, which is what keeps the document's own numbering, `show` rules and
    // reference destinations working on it.
    //
    // A section slide is a divider, so what it carries sits in the middle of
    // the page rather than at the top of it.
    let placed = if record.kind == "section" {
      align(center + horizon, body)
    } else {
      body
    }
    _chrome(record, repeated, placed)
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
  if theme != none and type(theme) != dictionary {
    fail-type(scope, "theme", theme, "a token dictionary, a light and dark pair, or none")
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
  // That one function also reads the mode and takes the defaults, so a deck
  // naming no theme still hears about a mistyped mode.
  let tokens = resolve-mode(theme, theme-mode, scope)
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
        prelude: if index == 0 or counts == none { [] } else { rewind(counts) },
        repeated: index > 0,
      )
    }
  }
}
