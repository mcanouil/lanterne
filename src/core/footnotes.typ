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
///! number the footnote would have taken rather than a fixed digit.
///! `notes/counter-findings.md` records the measurements and the conditions
///! they were taken under.
///!
///! Reading the counter here is safe, and the reason is narrower than "reading
///! is not writing", since this module does both. The value read reaches only
///! the placeholder's width: no counter update is derived from it, and the
///! update that follows is a constant. The value itself depends on document
///! order rather than on layout, so it settles in one pass, where the rejected
///! freezing mechanism fed a counter read back into a state that another slide
///! read in turn.
///!
///! A footnote written inside a `context` block is invisible to the traversal,
///! exactly as a marker is, so it is never replaced and still makes its entry a
///! step early.

#import "../utils/elements.typ": is-elem
#import "../utils/errors.typ": fail

/// Whether `node` is a footnote that makes an entry of its own.
///
/// `footnote(<label>)` is a second reference to a note that already exists: it
/// makes no entry and advances no counter, so it needs no placeholder and must
/// not be given one. `src/core/counters.typ` reads the same rule from here, so
/// the count a step is rewound by and the advance a placeholder makes cannot
/// fall out of step.
/// @category core
/// @returns bool
#let is-entry(node) = (
  is-elem(node, footnote) and type(node.fields().at("body", default: [])) != label
)

/// A hidden stand-in for `node`, the size of the mark it replaces.
///
/// The number is the one the footnote would take, read at the point the
/// placeholder sits, so several in one region number in sequence. The scheme is
/// the footnote's own when it sets one and the style's otherwise, since a
/// footnote numbered `"*"` reserves a different width from one numbered `"1"`.
/// The counter is advanced afterwards, exactly as the footnote would have
/// advanced it.
///
/// `keeps-labels` says whether this step is the one that keeps the labels of
/// the region the footnote sits in. A labelled footnote on that step is refused
/// rather than replaced: the placeholder cannot carry the label, and dropping it
/// would leave a reference failing with Typst's own message about a label that
/// does not exist.
/// @category core
/// @returns content
#let placeholder(node, keeps-labels: false) = {
  let fields = node.fields()
  if keeps-labels and fields.at("label", default: none) != none {
    fail(
      "footnote",
      "cannot keep the label "
        + repr(fields.label)
        + " on a footnote that is hidden on every step this render puts on a page",
      hint: "Label the text around the footnote, or render the step that reveals it.",
    )
  }
  let scheme = fields.at("numbering", default: auto)
  context {
    let taken = counter(footnote).get().first() + 1
    let resolved = if scheme == auto { footnote.numbering } else { scheme }
    hide(super(numbering(resolved, taken)))
  }
  counter(footnote).update(value => value + 1)
}
