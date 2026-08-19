///! A footnote that is hidden must not put an entry on the page.
///!
///! `hide` reserves space and lays its content out, so a footnote behind a
///! pause makes a real entry at the foot of the page: the separator rule and
///! the note itself appear a step before the text that refers to them.
///!
///! There is no way to hide an entry, so the footnote is replaced instead. What
///! stands in for it has to occupy exactly the space the mark would, or the
///! line reflows when the note is revealed, and it has to advance the footnote
///! counter, or the notes after it renumber between steps.
///!
///! The mark is a superscript of the footnote numbering, measured rather than
///! assumed: `measure(footnote[x]).width` and `measure(super[1]).width` agree,
///! and a two digit number is wider, which is why the placeholder carries the
///! number the footnote would have taken rather than a fixed digit. That number
///! is read from the live counter, which is a read of document state and not a
///! write, so it feeds no convergence loop. `notes/counter-findings.md` records
///! both measurements.

#import "../utils/elements.typ": is-elem

/// Whether `node` is a footnote that makes an entry of its own.
///
/// `footnote(<label>)` is a second reference to a note that already exists: it
/// makes no entry and advances no counter, so it needs no placeholder and must
/// not be given one.
/// @category core
/// @returns bool
#let is-entry(node) = (
  is-elem(node, footnote) and type(node.fields().at("body", default: [])) != label
)

/// A hidden stand-in for a footnote, the size of the mark it replaces.
///
/// The number is the one the footnote would take, read at the point the
/// placeholder sits, so several in one region number in sequence. The counter is
/// advanced afterwards, exactly as the footnote would have advanced it.
/// @category core
/// @returns content
#let placeholder() = {
  context hide(super(numbering(footnote.numbering, counter(footnote).get().first() + 1)))
  counter(footnote).update(value => value + 1)
}
