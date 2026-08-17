///! Step ranges, normalised to spans.
///!
///! A range is written as an integer, an array of integers, or a string in the
///! forms "2", "2-", "-3" and "2-4". All of them normalise to an array of
///! spans, each `(from: int, to: int or none)`, because an array form such as
///! `(1, 3, 5)` is a set of steps rather than an interval and one pair cannot
///! hold it. Every reader downstream then does arithmetic over one shape.
///!
///! Ranges are one based, and a malformed range fails rather than clamping. A
///! clamped range renders a deck that builds and is wrong, which is the failure
///! the whole package refuses.

#import "../utils/errors.typ": fail, fail-type

#let _EXPECTED = (
  "an integer, an array of integers, or a string of the form \"2\", \"2-\", \"-3\" or \"2-4\""
)

#let _DIGITS = regex("^[0-9]+$")

#let _bad(value, scope, name) = fail-type(scope, name, value, _EXPECTED)

// A step written as text. Rejects anything that is not a run of digits, and
// rejects zero, since a range is one based and step 0 is no step at all.
#let _as-step(digits, value, scope, name) = {
  if digits.match(_DIGITS) == none { _bad(value, scope, name) }
  let step = int(digits)
  if step < 1 { _bad(value, scope, name) }
  step
}

#let _from-string(value, scope, name) = {
  let parts = value.split("-")
  if parts.len() == 1 {
    let step = _as-step(parts.first(), value, scope, name)
    return ((from: step, to: step),)
  }
  if parts.len() != 2 { _bad(value, scope, name) }
  let (low, high) = parts
  // "-3" is every step up to 3, so its start is the first step rather than
  // absent: a span with no start would need a second optional field for a form
  // that already has a natural value.
  if low == "" and high == "" { _bad(value, scope, name) }
  if low == "" { return ((from: 1, to: _as-step(high, value, scope, name)),) }
  if high == "" { return ((from: _as-step(low, value, scope, name), to: none),) }
  let (start, end) = (_as-step(low, value, scope, name), _as-step(high, value, scope, name))
  if end < start {
    fail(
      scope,
      name + " ends before it starts; got " + repr(value),
      hint: "Write the lower step first, as \"2-4\".",
    )
  }
  ((from: start, to: end),)
}

/// Normalise a step range into an array of spans.
///
/// `scope` names the caller in any message this raises, because a range reaches
/// this from `step`, from `emit-step` and from the deck's `handout` option, and
/// an author told to fix `parse-range` has no such call to find.
///
/// `name` names the value in the same message, "range" by default. A caller
/// validating something else under that name, such as the deck's `handout`
/// option, passes its own so the message points at a parameter that exists.
/// @category core
/// @returns array
#let parse-range(value, scope, name: "range") = {
  if type(value) == int {
    if value < 1 { _bad(value, scope, name) }
    return ((from: value, to: value),)
  }
  if type(value) == array {
    if value.len() == 0 { _bad(value, scope, name) }
    return value.map(entry => {
      if type(entry) != int or entry < 1 { _bad(value, scope, name) }
      (from: entry, to: entry)
    })
  }
  if type(value) == str { return _from-string(value, scope, name) }
  _bad(value, scope, name)
}

/// Whether `step` falls inside any span.
///
/// `spans` must come from `parse-range`, which never returns an empty array;
/// this is not checked here.
/// @category core
/// @returns bool
#let in-spans(spans, step) = spans.any(span => (
  step >= span.from and (span.to == none or step <= span.to)
))

/// The lowest step any span mentions.
///
/// This is where a region's before zone ends. Every step below it renders the
/// region's `before` state, and every step above the spans that is not inside
/// one renders its `after` state.
///
/// `spans` must come from `parse-range`, which never returns an empty array;
/// this is not checked here.
/// @category core
/// @returns int
#let first-step(spans) = calc.min(..spans.map(span => span.from))

/// The highest step any span mentions.
///
/// An open ended span contributes its start and nothing beyond it, because a
/// range with no end needs no steps of its own past the one it opens on. This
/// is the rule that makes `uncover("3-", ...)` on a slide with no pause render
/// three steps; counting an open end as zero renders its content never.
///
/// `spans` must come from `parse-range`, which never returns an empty array;
/// this is not checked here.
/// @category core
/// @returns int
#let max-mentioned(spans) = (
  spans
    .map(span => if span.to == none { span.from } else { span.to })
    .fold(0, calc.max)
)
