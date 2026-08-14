///! Split a content sequence on a predicate.
///!
///! One splitter serves the whole package: applied with a heading predicate it
///! yields slides, applied with a marker predicate it yields steps. Matching
///! elements are dropped; empty segments are preserved so that a leading or
///! doubled match keeps its position.
///!
///! Only direct children are examined. A match nested inside a block, a list
///! item or a grid cell stays inside its segment and produces no boundary, so
///! a caller that must not miss one has to check the segments it gets back.

#let _SEQUENCE = [*a* b].func()

// A `sequence` exposes its children directly. Anything else, including a
// single merged text run, is treated as its own one-element sequence.
//
// `node.has("children")` is not the test: grid, table, stack, list and enum
// all have a `children` field, and treating one as a sequence would return
// its cells in place of the container itself.
#let _children(node) = if node.func() == _SEQUENCE { node.children } else { (node,) }

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
