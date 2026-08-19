///! A footnote that is hidden must not put an entry on the page.
///!
///! `hide` reserves space and lays its content out, so a footnote behind a
///! pause makes a real entry at the foot of the page: the separator rule and
///! the note itself appear a step before the text that refers to them.
///!
///! There is no way to hide an entry, so the footnote is replaced instead. What
///! stands in for it has to occupy exactly the space the mark would, or the
///! line reflows when the note is revealed.
///!
///! It also has to leave the counters where the footnote would have left them.
///! That is not the footnote counter alone: a figure or a numbered equation
///! written inside a note body advances its own counter too, and the slide's
///! rewind subtracts every increment the body makes whether the step made them
///! or not. Missing one drives the counter below zero, which Typst refuses
///! outright with `number must be at least zero`. The caller therefore pairs
///! this with the compensation `src/core/counters.typ` computes for the whole
///! footnote, rather than advancing one counter here.
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

/// The numbering scheme a footnote's mark is drawn in.
///
/// A footnote that sets its own `numbering` is drawn in that scheme, and one
/// that sets none takes `ambient`, the rule in force. It matters because a
/// footnote numbered `"*"` draws a different mark from one numbered `"1"`, so a
/// placeholder built from the ambient scheme alone reserves the wrong width.
///
/// `ambient` is passed in rather than read here, because reading a style needs
/// a context and this has to be testable without one.
/// @category core
/// @returns string, function, or none
#let scheme-of(node, ambient) = {
  let given = node.fields().at("numbering", default: auto)
  if given == auto { ambient } else { given }
}

/// A hidden stand-in for `node`, the size of the mark it replaces.
///
/// The number is the one the footnote would take, read at the point the
/// placeholder sits, so several in one region number in sequence. The scheme is
/// the footnote's own when it sets one and the style's otherwise, since a
/// footnote numbered `"*"` reserves a different width from one numbered `"1"`.
///
/// This reserves space and reads a counter; it advances nothing. The caller
/// emits the advance for everything the footnote would have numbered, its own
/// counter included, so a figure inside a note body is not forgotten.
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
  context {
    let taken = counter(footnote).get().first() + 1
    hide(super(numbering(scheme-of(node, footnote.numbering), taken)))
  }
}
