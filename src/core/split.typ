///! Split a content sequence on a predicate.
///!
///! One splitter serves the whole package: applied with a heading predicate it
///! yields slides, applied with a marker predicate it yields steps. Matching
///! elements are dropped; empty segments are preserved so that a leading or
///! doubled match keeps its position.
///!
///! Two functions read the one walk. `split-on` hands back the segments alone,
///! which is what a pause needs. `split-at` hands back each segment beside the
///! element that opened it, which is what a heading needs: a heading is both
///! the boundary and the slide's title, so dropping it loses the title.
///!
///! `split-at` can also leave a match where it was found, at the head of the
///! segment it opened. That is not a convenience: a match left in place stays
///! inside the style wrappers it was written under, so the rules in force over
///! it still reach it. A heading lifted out of them is no longer numbered, no
///! longer restyled by the document's own `show heading` rule, and no longer
///! referenceable.
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
///! Only element children are examined. A match nested inside a block, a list
///! item or a grid cell stays inside its segment and produces no boundary, so
///! a caller that must not miss one has to check the segments it gets back.
///!
///! A nested sequence is not such an element and is looked through. Nothing in
///! the content distinguishes markup written at body level from markup that
///! arrived as one value: `#include`, a `#let` fragment and a helper's return
///! value all land as a sequence among the body's children, and a deck written
///! across several files is the ordinary case rather than an exotic one. The
///! same reading resolves a group written as `#[...]`, whose contents likewise
///! produce boundaries whether or not it opens with a rule.

#import "../utils/elements.typ": SEQUENCE, STYLED, is-elem
#import "../utils/errors.typ": fail-type

// The nodes a match contributes to the segment it opened: itself when `keep`
// says so, and nothing otherwise.
#let _kept(node, keep) = {
  if keep != none and keep(node) { (node,) } else { () }
}

// The pieces `node` contributes to the split, as an array of
// `(nodes: (...), boundary: none or content)`. Every piece but the last is a
// finished segment; the last is open and joins whatever follows, so an array of
// one piece means no boundary was found.
//
// `boundary` is the match that opened the piece, and is `none` for a piece the
// body itself opened. It is carried through the wrapper rebuild below rather
// than wrapped, since a caller reads its fields rather than rendering it.
//
// The split is structural rather than flat: a wrapper is descended into and
// then put back around each piece its child produced, so a rule is re-applied
// exactly as many times as there are segments under it and never once per
// stretch of children between its nested wrappers. Applying `#set page` twice
// within one segment opens two page groups, so a body that rendered on one
// page comes back rendering on two.
//
// A nested `sequence` is descended into as well, because that is what markup
// arriving as one value looks like: an `#include`, a `#let` fragment and a
// helper's return value are all a single sequence sitting among the body's
// children, and a heading inside one has to open a slide or a deck written
// across several files collapses onto one page. `node.has("children")` is not
// the test: grid, table, stack, list and enum all have a `children` field, and
// treating one as a sequence would split it into its cells.
//
// `keep` decides, per match, whether the match stays at the head of the segment
// it opened. A match left in place stays inside the wrappers it was written
// under, which is the only way the rules in force over it still reach it.
#let _pieces(node, predicate, keep) = {
  if is-elem(node, STYLED) {
    // The positional order `(child, styles)` is the registry's recipe for
    // `styled`, verified in docs/notes/roundtrip-findings.md. A Typst upgrade
    // that changes it has to reach this call as well as src/core/registry.typ.
    //
    // A label is not a constructor parameter, so rebuilding the wrapper drops
    // it and it has to be reattached by markup, exactly as `_rebuild` does in
    // src/core/walk.typ. Content equality ignores labels, so nothing that
    // compares segments can notice the loss.
    let element-label = node.fields().at("label", default: none)
    let rebuilt = _pieces(node.child, predicate, keep).map(piece => (
      nodes: (STYLED(piece.nodes.sum(default: []), node.styles),),
      boundary: piece.boundary,
    ))
    if element-label == none { return rebuilt }
    // A label can sit on one piece only. Emitting it on each would make the
    // deck fail with a duplicate label, which is worse than a reference
    // landing at the end of the group. Specification 4.6 rules that a labelled
    // element behind a pause keeps its label on the final step, and the same
    // rule holds here.
    let last = rebuilt.last()
    let relabelled = (
      nodes: ([#(last.nodes.first())#element-label],),
      boundary: last.boundary,
    )
    return rebuilt.slice(0, -1) + (relabelled,)
  }
  if is-elem(node, SEQUENCE) {
    let pieces = ((nodes: (), boundary: none),)
    for child in node.children {
      let from-child = if is-elem(child, STYLED) or is-elem(child, SEQUENCE) {
        _pieces(child, predicate, keep)
      } else if predicate(child) {
        // The match closes the open piece and opens one of its own, which it
        // is the boundary of, and which it stays in when `keep` says so.
        ((nodes: (), boundary: none), (nodes: _kept(child, keep), boundary: child))
      } else {
        ((nodes: (child,), boundary: none),)
      }
      // The first piece a child yields continues the open piece, whose own
      // boundary stands; the rest are segments the child closed and are
      // appended with the boundaries that opened them.
      let open = pieces.last()
      open.nodes += from-child.first().nodes
      pieces.last() = open
      pieces += from-child.slice(1)
    }
    return pieces
  }
  if predicate(node) {
    return ((nodes: (), boundary: none), (nodes: _kept(node, keep), boundary: node))
  }
  ((nodes: (node,), boundary: none),)
}

// Both public functions take the same two arguments and report under their own
// name, since a message naming a function the author never called sends them to
// the wrong line.
#let _check(scope, body, predicate) = {
  // split-on: body must be content; got "a".
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  // split-on: predicate must be a function; got "not a function".
  if type(predicate) != function {
    fail-type(scope, "predicate", predicate, "a function")
  }
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
  _check("split-on", body, predicate)
  _pieces(body, predicate, none).map(piece => piece.nodes.sum(default: []))
}

/// Split `body` at every child satisfying `predicate`, keeping the boundaries.
///
/// The same walk as `split-on`, reporting what it matched: each segment arrives
/// as `(boundary: ..., body: ...)`, where `boundary` is the element that opened
/// it and is `none` for the first. A heading is both a slide boundary and the
/// slide's title, so a caller that only gets the segments cannot build a slide.
///
/// A boundary is dropped from the body it opened unless `keep` says otherwise.
/// `keep` is called on each match and decides, per match, whether it stays at
/// the head of its segment. That is what a heading needs: a heading left where
/// it was found stays inside the wrappers it was written under, so the
/// document's own rules still number it, restyle it and make it a reference
/// destination, while one lifted out of them silently loses all three.
///
/// The boundary is reported either way, and is always reported unwrapped, since
/// a caller reads its fields rather than rendering it.
/// @category core
/// @returns array
#let split-at(body, predicate, keep: none) = {
  _check("split-at", body, predicate)
  if keep != none and type(keep) != function {
    fail-type("split-at", "keep", keep, "a function or none")
  }
  _pieces(body, predicate, keep).map(piece => (
    boundary: piece.boundary,
    body: piece.nodes.sum(default: []),
  ))
}
