///! The preset that composes a page.
///!
///! `banded` puts a slide's title in a coloured band across the top, a rule and
///! a footer at the foot, and gives a section slide a page of its own. It
///! differs from `plain` in structure rather than only in colour, which is the
///! specification's own justification for the renderer slots: two presets
///! differing in palette would prove nothing about them.
///!
///! Three of the five slots. There is no progress region, because a progress
///! indicator reads a position in the deck and `state` reports a position within
///! one slide; that arrives with the tokens that name it.

#import "../../core/split.typ": is-blank
#import "../theme.typ": theme-tokens

// A title that came from a heading arrives as the heading the author wrote, so
// the document's own rules have already sized and styled it. One that came from
// `slide(title: ...)` is a plain value that no `show heading` rule reaches, so
// the theme sets the heading font and size itself.
//
// Wrapping the value in `heading(...)` instead would be worse than doing
// nothing: it mints a second heading, which numbers, outlines and bookmarks, and
// so puts an explicit slide in the outline it was never in.
#let _title-text(tokens, state) = {
  if state.title-source == "heading" { return state.title }
  text(
    font: tokens.font-heading,
    weight: tokens.weight-heading,
    size: tokens.size-base * tokens.scale-ratio,
    state.title,
  )
}

#let _header(info: (:), tokens: none, state: none) = {
  // A slide with no title has nothing for this region to hold, so the region
  // takes no space rather than drawing an empty band. A header handed a title
  // must place it, so this is the one case that may decline.
  if state.title == none { return none }
  // The band is as tall as what it holds, and `header-height` sets the padding
  // above and below what it holds rather than a hard height, so a band holding
  // one line comes to about that height and one holding two comes to more.
  //
  // A quarter of the token on each side, rather than the token less a line:
  // subtracting a line means comparing a mixed length with zero to keep it
  // positive, and Typst refuses that comparison, which is the same rule the
  // token vocabulary states for a non-negative length.
  //
  // A hard height was the first shape and it clipped. A title long enough to
  // wrap had its second line cut through the middle of the glyphs, and a theme
  // given `header-height: 0` lost the title altogether, since the title had
  // already been taken out of the body to be put in a band with no room in it.
  // Sized by its content, the band grows and the body moves down, which is a
  // page a reader can still read.
  block(
    width: 100%,
    fill: tokens.accent,
    inset: (x: tokens.gutter, y: tokens.header-height / 4),
    text(fill: tokens.accent-fg, _title-text(tokens, state)),
  )
}

#let _footer(info: (:), tokens: none, state: none) = {
  // Sized by its content for the same reason: a deck title long enough to wrap
  // ran off the bottom of the page when this row was fixed.
  block(width: 100%, inset: (bottom: tokens.footer-height / 4), {
    line(length: 100%, stroke: tokens.stroke-width + tokens.border)
    v(tokens.gutter / 2, weak: true)
    text(
      size: tokens.size-base / tokens.scale-ratio / tokens.scale-ratio,
      fill: tokens.muted,
      info.at("title", default: []),
    )
  })
}

#let _section(info: (:), tokens: none, state: none) = {
  // A section slide is a divider, so the band gives way to the whole page and
  // the title sits in the middle of it. The body follows, since a section slide
  // may carry a sentence under its heading.
  align(center + horizon, block(width: 100%, {
    text(fill: tokens.accent, _title-text(tokens, state))
    if not is-blank(state.body) [
      #v(tokens.gutter)
      #state.body
    ]
  }))
}

/// The banded theme: a title band, a footer rule, and a section slide.
///
/// It supplies `render-header`, `render-footer` and `render-section-slide`, and
/// reads `accent`, `accent-fg`, `muted`, `border`, `stroke-width`,
/// `header-height`, `footer-height` and `gutter`.
///
/// The header declines a slide with no title, which is the one case a header
/// may decline: a header handed a title has to place it, since taking the title
/// out of the body is what made it placeable.
/// @category theme
/// @stability experimental
/// @param ..overrides The tokens to set, named only, as `theme-tokens` takes them.
/// @returns dictionary
/// @examples-static
/// ```typst
/// #show: deck.with(theme: theme-banded(accent: rgb("#1f5fa9")))
/// ```
#let theme-banded(..overrides) = theme-tokens(
  slots: (
    render-header: _header,
    render-footer: _footer,
    render-section-slide: _section,
  ),
  ..overrides,
)
