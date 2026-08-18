///! What a slide advances, counted rather than captured.
///!
///! A slide renders one page per step, and each page emits the slide's body
///! again, so everything the document numbers is numbered again. A figure
///! behind a pause takes a new number on every step, and the slide after it
///! continues from the inflated value.
///!
///! The fix has to leave the counters where each step found them. Capturing a
///! counter with `get` at the start of a slide and putting the value back on
///! the next step is the obvious way and does not work: the captured value is
///! introspective, it reaches the next slide through document state, and the
///! information advances about one slide per layout run where Typst allows
///! five. Three stepped slides already fail to converge, and the deck renders
///! wrong numbers rather than failing. `notes/counter-findings.md` records the
///! measurement.
///!
///! So nothing here reads a counter. The number of increments a body makes is
///! counted from the body itself, and the shift is relative: every step after
///! the first rewinds by that count, and a region that resolves to `removed`
///! advances by its own count in place, so that every step of a slide makes
///! exactly the same increments and numbers identically.
///!
///! Only the eligibility test reads anything, and it reads a style rather than
///! state. A figure advances its counter unless its numbering is `none`, an
///! equation advances only when it is block level and numbered, and a footnote
///! always advances, since Typst rejects a footnote numbering of `none`. An
///! instance that sets its own numbering is counted apart from one that takes
///! it from a set rule, because only the second has to be read at render time.
///!
///! That read happens where the shift is written, which is the head of a step
///! page for a rewind and the region's own position for an advance, and it is
///! per family rather than per figure kind. A numbering turned off inside a
///! slide body, or for one figure kind alone, is therefore not seen.
///! `notes/counter-findings.md` records both boundaries.
///!
///! Two counters are deliberately absent. `table` has no counter in Typst at
///! all, and `heading` is hierarchical, so a relative shift cannot invert it:
///! a heading is kept from advancing instead, by a set rule on the pages that
///! repeat it.

#import "walk.typ": MAX-DEPTH, collect
#import "../utils/elements.typ": is-elem
#import "../utils/errors.typ": fail-type

// Which counter a figure advances. Typst infers a kind from the body when the
// author sets none, and it sees through a wrapper, so `figure([#table(...)])`
// is a table figure exactly as `figure(table(...))` is. Anything that is
// neither a table nor a raw block is an image figure, which is Typst's own
// rule rather than a guess.
//
// A body holding more than one of them takes the kind of whichever comes
// first, which was measured rather than assumed: reading the table first would
// put the shift on the table counter while the caption drew its number from
// the counter of the element that actually opened the body.
//
// `image` is in the search as well as being the fallback, because it only wins
// by default when nothing else is there: an image written before a table makes
// an image figure, and an image written after one does not.
#let _KINDS = (image, table, raw)

#let _kind-of(node, max-depth) = {
  let fields = node.fields()
  let given = fields.at("kind", default: auto)
  if given != auto { return given }
  let candidates = collect(
    fields.at("body", default: []),
    child => _KINDS.any(kind => is-elem(child, kind)),
    max-depth: max-depth,
  )
  if candidates.len() == 0 { return image }
  candidates.first().func()
}

// Where an instance takes its numbering from. An absent field means the style
// decides, which is the only case that has to be read at render time.
#let _source-of(node) = {
  let given = node.fields().at("numbering", default: auto)
  if given == auto { return "styled" }
  if given == none { return "off" }
  "forced"
}

#let _tally(entries, kind, source) = {
  let index = entries.position(entry => entry.kind == kind)
  if index == none {
    return entries + ((kind: kind, styled: int(source == "styled"), forced: int(source == "forced")),)
  }
  let entry = entries.at(index)
  entries.at(index) = (
    kind: kind,
    styled: entry.styled + int(source == "styled"),
    forced: entry.forced + int(source == "forced"),
  )
  entries
}

/// Count the counter increments `body` makes, per counter.
///
/// The figures come back one entry per kind, in the order the walk reaches
/// them, because Typst numbers a figure through the counter of its kind and
/// not through `counter(figure)`. An element whose numbering is `none` is
/// absent altogether, since it advances nothing.
///
/// The count is the same whatever step the body is resolved for: it is taken
/// from the body as written, markers and all, which is what makes it the
/// invariant every step is held to.
///
/// `max-depth` bounds the walk. See `MAX-DEPTH`.
/// @category core
/// @returns dictionary
#let increments(body, max-depth: MAX-DEPTH) = {
  if type(body) != content {
    fail-type("increments", "body", body, "content")
  }
  let numbered = collect(
    body,
    node => is-elem(node, figure) or is-elem(node, math.equation) or is-elem(node, footnote),
    max-depth: max-depth,
  )

  let figures = ()
  let equations = (styled: 0, forced: 0)
  let footnotes = 0
  for node in numbered {
    let source = _source-of(node)
    if is-elem(node, footnote) {
      // Typst rejects a footnote numbering of none, so a footnote always
      // advances and nothing about it has to be read from the style. One
      // written as `footnote(<label>)` is a second reference to a note that
      // already exists, and it advances nothing: counting it would rewind the
      // counter further than the slide moved it.
      if type(node.fields().at("body", default: [])) != label {
        footnotes += 1
      }
    } else if source == "off" {
      continue
    } else if is-elem(node, figure) {
      figures = _tally(figures, _kind-of(node, max-depth), source)
    } else if node.fields().at("block", default: false) {
      // An inline equation is never numbered, so it never advances the
      // counter, and a block equation nests an inline one inside itself.
      equations.insert(source, equations.at(source) + 1)
    }
  }

  (figures: figures, equations: equations, footnotes: footnotes)
}

// One shift per counter, `sign` deciding the direction. The styled part is
// read inside `context` because a set rule decides it, and reading a style is
// not introspection: it feeds no convergence loop, where reading a counter
// would.
#let _shift(counts, sign) = {
  let shifted = []
  for entry in counts.figures {
    shifted += context {
      let delta = entry.forced + if figure.numbering != none { entry.styled } else { 0 }
      if delta != 0 {
        counter(figure.where(kind: entry.kind)).update(value => value + sign * delta)
      }
    }
  }
  if counts.equations.styled + counts.equations.forced > 0 {
    shifted += context {
      let delta = counts.equations.forced + if math.equation.numbering != none {
        counts.equations.styled
      } else {
        0
      }
      if delta != 0 {
        counter(math.equation).update(value => value + sign * delta)
      }
    }
  }
  if counts.footnotes != 0 {
    shifted += counter(footnote).update(value => value + sign * counts.footnotes)
  }
  shifted
}

/// Put the counters back by what `counts` says a body advanced them.
///
/// Written at the head of every step of a slide but the first, so each step
/// starts where the slide started and numbers identically.
/// @category core
/// @returns content
#let rewind(counts) = _shift(counts, -1)

/// Advance the counters by what `counts` says a body would have advanced them.
///
/// Written where a region resolved to `removed` leaves nothing behind, so the
/// content after it keeps the numbers it has on the steps where the region is
/// laid out.
/// @category core
/// @returns content
#let advance(counts) = _shift(counts, 1)
