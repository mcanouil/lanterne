///! Split a content sequence on a predicate.
///!
///! One splitter serves the whole package: applied with a heading predicate it
///! yields slides, applied with a marker predicate it yields steps. Matching
///! elements are dropped; empty segments are preserved so that a leading or
///! doubled match keeps its position.
///!
///! A `set` or `show` rule wraps everything it governs in a `styled` element,
///! so the boundaries that follow one sit inside that wrapper rather than
///! beside it. Enumeration peels the wrapper and splices what it held into
///! the child list, carrying the styles that were removed so each child can
///! be handed back wrapped as it was found. This is the shape a deck actually
///! receives: `#show: deck.with(...)` hands the function a `styled` element
///! whenever the document sets anything after that line.
///!
///! `#show: doc => f(doc)` is a different thing and is not covered. It is
///! applied where it is written, so the body becomes whatever `f` returned,
///! and a container it returns is a container like any other.
///!
///! Only direct children are examined. A match nested inside a block, a list
///! item or a grid cell stays inside its segment and produces no boundary, so
///! a caller that must not miss one has to check the segments it gets back.

#import "../utils/errors.typ": fail-type

#let _SEQUENCE = [*a* b].func()
#let _STYLED = text(size: 12pt)[x].func()

// The children of `node`, each paired with the styles peeled off above it.
//
// A `sequence` exposes its children directly. Anything else, including a
// single merged text run, is its own one-element sequence.
//
// `node.has("children")` is not the test: grid, table, stack, list and enum
// all have a `children` field, and treating one as a sequence would return
// its cells in place of the container itself.
#let _entries(node, styles) = {
  if type(node) != content { return ((node: node, styles: styles),) }
  if node.func() == _STYLED { return _entries(node.child, styles + (node.styles,)) }
  if node.func() == _SEQUENCE {
    return node
      .children
      .map(child => if type(child) == content and child.func() == _STYLED {
        _entries(child, styles)
      } else {
        ((node: child, styles: styles),)
      })
      .sum(default: ())
  }
  ((node: node, styles: styles),)
}

// Styles were peeled outermost first, so they are re-applied innermost first.
#let _restyle(body, styles) = styles.rev().fold(body, (acc, style) => _STYLED(acc, style))

/// Split `body` into segments at every child satisfying `predicate`.
///
/// `predicate` is applied to the child with its style wrappers removed, since
/// a predicate written for a marker or a heading cannot be expected to see
/// through one. The child kept in a segment is the wrapped form, so the rules
/// in force over it survive the split.
/// @category core
/// @returns array
#let split-on(body, predicate) = {
  let scope = "split-on"
  // split-on: body must be content; got "a".
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  // split-on: predicate must be a function; got "not a function".
  if type(predicate) != function {
    fail-type(scope, "predicate", predicate, "a function")
  }
  let segments = ()
  let current = ()
  for entry in _entries(body, ()) {
    if predicate(entry.node) {
      segments.push(current.sum(default: []))
      current = ()
    } else {
      current.push(_restyle(entry.node, entry.styles))
    }
  }
  segments.push(current.sum(default: []))
  segments
}
