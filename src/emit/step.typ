///! The machine facing step surface.
///!
///! Plain dictionaries, strings and content only: no closure arguments, no
///! positional variadics, and every enumerated value a string. A Lua filter
///! emitting this has nothing to learn beyond four key names.
///!
///! It delegates to `step` rather than reimplementing it, and passes its own
///! scope so a malformed range emitted by a filter reports under `emit-step`
///! while one written by hand reports under `step`. The two surfaces therefore
///! converge on one validated primitive, and neither imports the other.

#import "../core/steps.typ": step
#import "../utils/errors.typ": fail

/// A stepped region, from a dictionary of strings and content.
///
/// `range` is required and takes the string forms `"2"`, `"2-"`, `"-3"` and
/// `"2-4"`, or an integer. `before` and `after` name the states, as strings.
/// @category emit
/// @stability experimental
/// @returns content
#let emit-step(range: none, before: "hidden", after: "visible", body: []) = {
  let scope = "emit-step"
  if range == none {
    fail(
      scope,
      "range is required",
      hint: "Write emit-step(range: \"2-\", body: [...]).",
    )
  }
  step(range, body, before: before, after: after, scope: scope)
}
