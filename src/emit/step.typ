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
/// The machine facing counterpart to `step`: plain dictionaries, strings and
/// content only, no closure arguments and no positional variadics, so a filter
/// emitting it has nothing to learn beyond four key names.
///
/// It delegates to `step` rather than reimplementing it, passing its own scope,
/// so a malformed range emitted by a filter reports under `emit-step` while one
/// written by hand reports under `step`.
/// @category emit
/// @stability experimental
/// @param range The steps the region is visible on. An integer or a string such as `"2"`, `"2-"`, `"-3"` or `"2-4"`. Required.
/// @param before The state below the range, as a string.
/// @param after The state above the range, as a string.
/// @param body The region.
/// @returns content
/// @examples-static
/// ```typst
/// #emit-step(range: "2-", body: [Appears from step two.])
/// ```
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
