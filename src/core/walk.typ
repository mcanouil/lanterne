///! Generic content traversal.
///!
///! Detection walks `fields()` recursively and is total: a marker nested in
///! any element, registered or not, is found. Reconstruction is added in a
///! later task; detection alone guarantees a marker is never silently lost.

#import "marker.typ": is-marker

/// Whether `node` contains a lanterne marker at any depth.
///
/// `node` need not be content: it is called on every field value found while
/// walking `fields()`, which includes arrays of content and arrays of arrays
/// (a grid's children, for instance), as well as plain values such as
/// lengths and dictionaries that never contain a marker.
/// @category core
/// @returns bool
#let has-marker(node) = {
  if is-marker(node) { return true }
  if type(node) == array {
    return node.any(has-marker)
  }
  if type(node) != content { return false }
  for (_, value) in node.fields() {
    if has-marker(value) { return true }
  }
  false
}
