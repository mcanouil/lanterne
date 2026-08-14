///! Split a content sequence on a predicate.
///!
///! One splitter serves the whole package: applied with a heading predicate it
///! yields slides, applied with a marker predicate it yields steps. Matching
///! elements are dropped; empty segments are preserved so that a leading or
///! doubled match keeps its position.
///!
///! A `set` or `show` rule wraps everything it governs in a `styled` element,
///! so the boundaries that follow one sit inside that wrapper rather than
///! beside it. The split descends through the wrapper and puts it back around
///! each segment found underneath, so a segment carries the rules in force
///! over it and carries each of them once. This is the shape a deck actually
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

#import "../utils/elements.typ": SEQUENCE, STYLED, is-elem
#import "../utils/errors.typ": fail-type

// The pieces `node` contributes to the split, as an array of arrays of nodes.
// Every piece but the last is a finished segment; the last is open and joins
// whatever follows, so an array of one piece means no boundary was found.
//
// The split is structural rather than flat: a wrapper is descended into and
// then put back around each piece its child produced, so a rule is re-applied
// exactly as many times as there are segments under it and never once per
// stretch of children between its nested wrappers. Applying `#set page` twice
// within one segment opens two page groups, so a body that rendered on one
// page comes back rendering on two.
//
// A `sequence` is descended into only when it is the body itself or sits
// under a wrapper, which is what keeps the rule that only direct children are
// examined. `node.has("children")` is not the test: grid, table, stack, list
// and enum all have a `children` field, and treating one as a sequence would
// split it into its cells.
#let _pieces(node, predicate) = {
  if is-elem(node, STYLED) {
    // The positional order `(child, styles)` is the registry's recipe for
    // `styled`, verified in docs/notes/roundtrip-findings.md. A Typst upgrade
    // that changes it has to reach this call as well as src/core/registry.typ.
    return _pieces(node.child, predicate).map(piece => (
      (STYLED(piece.sum(default: []), node.styles),)
    ))
  }
  if is-elem(node, SEQUENCE) {
    let pieces = ((),)
    for child in node.children {
      let from-child = if is-elem(child, STYLED) {
        _pieces(child, predicate)
      } else if predicate(child) {
        ((), ())
      } else {
        ((child,),)
      }
      // The first piece a child yields continues the open piece; the rest are
      // segments the child closed and are appended as they are.
      pieces.last() += from-child.first()
      pieces += from-child.slice(1)
    }
    return pieces
  }
  if predicate(node) { return ((), ()) }
  ((node,),)
}

/// Split `body` into segments at every child satisfying `predicate`.
///
/// `predicate` is applied to the child with its style wrappers removed, since
/// a predicate written for a marker or a heading cannot be expected to see
/// through one. Every segment is handed back inside the wrappers it was found
/// under, including an empty one, so the rules in force over it survive the
/// split.
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
  _pieces(body, predicate).map(piece => piece.sum(default: []))
}
