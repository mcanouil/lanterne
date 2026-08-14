///! Generic content traversal.
///!
///! Detection walks `fields()` recursively: a marker nested in any element,
///! registered or not, is found, so long as it is reachable through
///! `fields()`. Reconstruction is added in a later task.
///!
///! One shape is not reachable. A `context` block reports no fields at all
///! until layout resolves it, so `(context [#pause]).fields()` is `(:)` and
///! nothing inside it can be seen. Markers held in a closure or in a
///! dictionary-valued field are invisible for the same reason. A step
///! boundary written inside `context` is therefore lost, and `#pause` has to
///! be written outside the context block.

#import "marker.typ": is-marker
#import "../utils/errors.typ": fail

// Typst aborts with `maximum function call depth exceeded` somewhere between
// 25 and 30 nesting levels, from inside library internals and with no source
// location for the offending content. The walk stops just short of that so
// the failure names the cause instead.
#let _MAX-DEPTH = 24

#let _has-marker(node, depth) = {
  if is-marker(node) { return true }
  if depth > _MAX-DEPTH {
    fail(
      "walk",
      "content is nested more than " + str(_MAX-DEPTH) + " levels deep",
      hint: "Typst cannot recurse further; flatten the nesting on this slide.",
    )
  }
  if type(node) == array {
    return node.any(child => _has-marker(child, depth + 1))
  }
  if type(node) != content { return false }
  for (_, value) in node.fields() {
    if _has-marker(value, depth + 1) { return true }
  }
  false
}

/// Whether `node` contains a lanterne marker at any depth.
///
/// `node` need not be content: it is called on every field value found while
/// walking `fields()`, which includes arrays of content and arrays of arrays
/// (a grid's children, or a matrix's rows) as well as plain values such as
/// lengths and dictionaries that never contain a marker.
///
/// Content inside a `context` block is not reachable through `fields()` and
/// is not searched. See the module header.
/// @category core
/// @returns bool
#let has-marker(node) = _has-marker(node, 0)
