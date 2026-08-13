///! Split a content sequence on a predicate.
///!
///! One splitter serves the whole package: applied with a heading predicate it
///! yields slides, applied with a marker predicate it yields steps. Matching
///! elements are dropped; empty segments are preserved so that a leading or
///! doubled match keeps its position.

// A `sequence` exposes its children directly. Anything else, including a
// single merged text run, is treated as its own one-element sequence.
#let _children(node) = if node.has("children") { node.children } else { (node,) }

/// Split `body` into segments at every child satisfying `predicate`.
/// @category core
/// @returns array
#let split-on(body, predicate) = {
  let segments = ()
  let current = ()
  for child in _children(body) {
    if predicate(child) {
      segments.push(current.sum(default: []))
      current = ()
    } else {
      current.push(child)
    }
  }
  segments.push(current.sum(default: []))
  segments
}
