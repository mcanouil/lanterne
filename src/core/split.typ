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
///!
///! One asymmetry follows from peeling. A content block that opens with a
///! rule is a `styled` element, so it is looked through and a match inside it
///! does produce a boundary, while the same block without a rule is a plain
///! nested sequence and does not. Nothing in the content distinguishes a rule
///! written at body level from one written inside a group, so the ambiguity
///! is resolved in favour of finding the boundary.

#import "../utils/errors.typ": fail-type

#let _SEQUENCE = [*a* b].func()
#let _STYLED = text(size: 12pt)[x].func()

// The children of `node` in order, grouped into runs that shared a wrapper.
//
// A run rather than a child is the unit, because the styles have to go back
// on around a whole run. A `set page` re-applied to each child separately
// opens a page group per child, so a body that rendered on one page comes
// back rendering on as many pages as it has children. Grouping is by shared
// origin and not by comparing styles, since two `styles` values never compare
// equal, not even when the same rule produced both.
//
// A `sequence` exposes its children directly. Anything else, including a
// single merged text run, is its own one-element sequence.
//
// `node.has("children")` is not the test: grid, table, stack, list and enum
// all have a `children` field, and treating one as a sequence would return
// its cells in place of the container itself.
#let _runs(node, styles) = {
  if type(node) != content { return ((styles: styles, nodes: (node,)),) }
  if node.func() == _STYLED { return _runs(node.child, styles + (node.styles,)) }
  if node.func() != _SEQUENCE { return ((styles: styles, nodes: (node,)),) }

  let runs = ()
  let pending = ()
  for child in node.children {
    if type(child) == content and child.func() == _STYLED {
      if pending.len() > 0 {
        runs.push((styles: styles, nodes: pending))
        pending = ()
      }
      runs += _runs(child, styles)
    } else {
      pending.push(child)
    }
  }
  if pending.len() > 0 { runs.push((styles: styles, nodes: pending)) }
  runs
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
  for run in _runs(body, ()) {
    let pending = ()
    for node in run.nodes {
      if predicate(node) {
        if pending.len() > 0 {
          current.push(_restyle(pending.sum(default: []), run.styles))
          pending = ()
        }
        segments.push(current.sum(default: []))
        current = ()
      } else {
        pending.push(node)
      }
    }
    if pending.len() > 0 {
      current.push(_restyle(pending.sum(default: []), run.styles))
    }
  }
  segments.push(current.sum(default: []))
  segments
}
