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

#import "../core/slides.typ": slides
#import "../theme/theme.typ": theme-merge, theme-tokens
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

#let _slide-page(record, tokens, paper) = {
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
    // The title is not placed here. It is the heading the author wrote, still
    // at the head of the body and still inside the wrappers it was written
    // under, which is what keeps the document's own numbering, `show` rules and
    // reference destinations working on it.
    //
    // A section slide is a divider, so what it carries sits in the middle of
    // the page rather than at the top of it.
    if record.kind == "section" {
      align(center + horizon, record.body)
    } else {
      record.body
    }
  })
}

/// Render a document body as slides.
///
/// Written as the document's show rule:
///
/// ```typst
/// #show: deck.with(theme: theme-tokens(), slide-level: 2)
/// ```
///
/// `theme` is a token dictionary from `theme-tokens` or `theme-merge`, and
/// defaults to the canonical one. `aspect-ratio` selects the page shape.
/// `slide-level` is the heading level that opens a slide, per `slides`. `info`
/// sets the document metadata and takes `title`, `author` and `date`.
/// @category deck
/// @returns content
#let deck(
  body,
  theme: none,
  aspect-ratio: "16-9",
  slide-level: 2,
  info: (:),
) = {
  let scope = "deck"
  if aspect-ratio not in _PAPERS {
    fail-enum(scope, "aspect-ratio", aspect-ratio, _PAPERS.keys())
  }
  if theme != none and type(theme) != dictionary {
    fail-type(scope, "theme", theme, "a token dictionary or none")
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
  // The theme is validated by the one function that validates a theme, so a
  // token rejected here reads the same as one rejected where it was written.
  let tokens = if theme == none { theme-tokens() } else { theme-merge(theme, (:)) }
  // The split validates `body` and `slide-level` under this scope, so the
  // message names the function the author called and there is one copy of it.
  let records = slides(body, slide-level: slide-level, scope: scope)

  // Metadata is set before any page is opened, because Typst resolves the
  // document's own properties once and before it lays anything out.
  set document(..info)
  for record in records {
    _slide-page(record, tokens, _PAPERS.at(aspect-ratio))
  }
}
