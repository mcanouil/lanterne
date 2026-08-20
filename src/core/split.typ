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

#import "marker.typ": is-marker
#import "../utils/elements.typ": SEQUENCE, SPACE, STYLED, is-elem
#import "../utils/errors.typ": fail, fail-type

/// Whether nothing in `node` puts a mark on the page.
///
/// Markup writes a space or a paragraph break wherever a line separates two
/// children, so content that reads as empty is a run of them, and a marker
/// renders as nothing by construction.
///
/// Both callers need the same answer. The splitter places a divided group's
/// label on the first piece that carries something, and `slides` drops a
/// lead-in segment that carries nothing, so a piece one of them called empty
/// and the other did not would be a label placed on a segment that is then
/// discarded.
/// @category core
/// @returns bool
#let is-blank(node) = {
  if is-elem(node, STYLED) { return is-blank(node.child) }
  if is-elem(node, SEQUENCE) { return node.children.all(is-blank) }
  if is-marker(node) { return true }
  is-elem(node, SPACE) or is-elem(node, parbreak) or is-elem(node, linebreak)
}

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
// A label reattached to exactly one piece of a group the split divided.
//
// It goes on the first piece that carries something, rather than on the first
// piece outright: a group whose first child is a boundary opens with an empty
// piece, and a label there is a reference that resolves to a page showing
// nothing, or none at all once the splitter drops a blank lead-in segment.
// Emitting it on every piece is not an option, since the deck would then fail
// with a duplicate label.
//
// Within that piece the label goes on the first node that carries something,
// not on the piece as a whole. Markup attaches a label to the last element of
// the content it follows, and the last element of a piece is usually the space
// that separated it from what came next; such a label is dropped when the
// spaces around a boundary are merged, and the deck then fails on a reference
// to a label that no longer exists.
//
// Specification 4.6 rules that a label stays with the first appearance of what
// carries it, so a reference lands where the group opens rather than where it
// ends.
#let _relabel(pieces, element-label, carrying: none) = {
  if element-label == none { return pieces }
  // Emptiness is read from the pieces as they were before a wrapper was put
  // back around them, since a wrapper around nothing still renders nothing,
  // and it is the same test `slides` drops a blank segment by.
  let read = if carrying == none { pieces } else { carrying }
  // A group the split did not divide keeps its label wherever it sits, blank
  // or not: there is no second piece for it to compete with, and an empty
  // labelled group is a legitimate anchor.
  let index = if pieces.len() == 1 {
    0
  } else {
    read.position(piece => piece.nodes.any(node => not is-blank(node)))
  }
  if index == none {
    fail(
      "split",
      "cannot place the label " + repr(element-label) + ", because every piece of the group it marks is empty",
      hint: "Label an element inside the group rather than the group itself.",
    )
  }
  let nodes = pieces.at(index).nodes
  let inner = nodes.position(node => not is-blank(node))
  let target = if inner == none { nodes.len() - 1 } else { inner }
  nodes.at(target) = [#(nodes.at(target))#element-label]
  pieces.at(index) = (nodes: nodes, boundary: pieces.at(index).boundary)
  pieces
}

#let _pieces(node, predicate, keep) = {
  if is-elem(node, STYLED) {
    // The positional order `(child, styles)` is the registry's recipe for
    // `styled`, verified in notes/roundtrip-findings.md. A Typst upgrade
    // that changes it has to reach this call as well as src/core/registry.typ.
    //
    // A label is not a constructor parameter, so rebuilding the wrapper drops
    // it and it has to be reattached by markup, exactly as `_rebuild` does in
    // src/core/walk.typ. Content equality ignores labels, so nothing that
    // compares segments can notice the loss.
    let element-label = node.fields().at("label", default: none)
    let inner = _pieces(node.child, predicate, keep)
    let rebuilt = inner.map(piece => (
      nodes: (STYLED(piece.nodes.sum(default: []), node.styles),),
      boundary: piece.boundary,
    ))
    return _relabel(rebuilt, element-label, carrying: inner)
  }
  if is-elem(node, SEQUENCE) {
    // A label on a sequence is read exactly as one on a wrapper is. Without
    // this, a label on a plain group that a pause cuts through is dropped and
    // a reference to it fails with a message about a label that does not
    // exist, which names neither the group nor the pause.
    let element-label = node.fields().at("label", default: none)
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
    return _relabel(pieces, element-label)
  }
  if predicate(node) {
    return ((nodes: (), boundary: none), (nodes: _kept(node, keep), boundary: node))
  }
  ((nodes: (node,), boundary: none),)
}

// The head and the rest of `node`, given whether the head has already been
// taken further left. `found` is the flag on the way in and on the way out, so
// a call took the head exactly when it was false going in and true coming out.
//
// This mirrors `_pieces` rather than calling it. `_pieces` matches every
// boundary, so recombining pieces 1 to n would mean summing separately wrapped
// pieces, and a `#set page` applied twice within one segment opens two page
// groups: a body that rendered on one page would come back rendering on two.
// `_relabel` cannot be reused either, since it places a label among n pieces
// while this places one among exactly two, under a different rule.
//
// The wrappers are put back around each half, so the rules in force over the
// head still reach it wherever the caller places it. That is the whole purpose
// of the function.
#let _head-pieces(node, predicate, found) = {
  if is-elem(node, STYLED) {
    let element-label = node.fields().at("label", default: none)
    let inner = _head-pieces(node.child, predicate, found)
    let took = not found and inner.found
    let head = if took { STYLED(inner.head, node.styles) } else { [] }
    let rest = STYLED(inner.rest, node.styles)
    // A label on a wrapper marks the slide's content, so it stays with the
    // rest. It falls to the head only when the rest carries nothing, which is
    // a title-only slide: a label on nothing at all is a reference that
    // resolves to a page showing nothing, and `_relabel` refuses that case
    // rather than degrading.
    if element-label != none {
      if is-blank(rest) and took {
        head = [#head#element-label]
      } else {
        rest = [#rest#element-label]
      }
    }
    return (head: head, rest: rest, found: inner.found)
  }
  if is-elem(node, SEQUENCE) {
    let element-label = node.fields().at("label", default: none)
    let head = []
    let parts = ()
    let seen = found
    for child in node.children {
      let inner = _head-pieces(child, predicate, seen)
      if not seen and inner.found { head = inner.head }
      parts.push(inner.rest)
      seen = inner.found
    }
    let took = not found and seen
    let rest = parts.sum(default: [])
    if element-label != none {
      if is-blank(rest) and took {
        head = [#head#element-label]
      } else {
        rest = [#rest#element-label]
      }
    }
    return (head: head, rest: rest, found: seen)
  }
  // The predicate sees the child with its wrappers already peeled, because the
  // two branches above descend before this is reached. A blank child never
  // matches a caller's predicate, so a body opening with a space still finds
  // its heading: this is the first child that satisfies the predicate rather
  // than the first child.
  if not found and predicate(node) {
    return (head: node, rest: [], found: true)
  }
  (head: [], rest: node, found: found)
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

/// Take the first child satisfying `predicate` out of `body`.
///
/// Hands back `(head, rest, found)`. `head` is that child inside the style
/// wrappers it was found under, `rest` is everything else inside the same
/// wrappers, and `found` says whether anything matched.
///
/// This is what a slide title needs and the other two splitters cannot give.
/// `split-on` and `split-at` cut at every match and hand back a run of
/// segments; a title is one element, taken out, with the body left whole. A
/// theme's header slot wants the title as a value it can place, and a heading
/// lifted out of its wrappers silently loses its numbering, the document's own
/// `show heading` rule and the destination a reference resolves to.
///
/// Both halves carry the wrappers, so the rules in force over the title reach
/// it wherever it is placed. A `set` or `show` rule written after
/// `#show: deck.with(...)` governs the title as much as the body, and the point
/// of taking the title out is to move it, not to take it out of its rules.
///
/// The first child that *satisfies the predicate*, not the first child. Markup
/// writes a space wherever a line separates two children, and a blank child
/// matches no caller's predicate, so a body that opens with one still finds its
/// heading. Only the first match moves: a heading written inside a slide is
/// content, and the caller's predicate decides which one is the title.
///
/// A label written on a wrapper or a sequence stays with the rest, since it
/// marks the slide's content and the title is the part being moved away from
/// it. It falls to the head when the rest carries nothing, which is the
/// title-only slide specification 4.1 allows: a label on nothing at all is a
/// reference resolving to a page that shows nothing. A label on the heading
/// itself is one of its fields and travels with it either way, which is what
/// makes a reference to a labelled slide resolve.
///
/// With no match, `body` comes back as it went in rather than rebuilt, so a
/// caller that asks and is refused has changed nothing.
/// @category core
/// @returns dictionary
#let split-head(body, predicate) = {
  _check("split-head", body, predicate)
  let cut = _head-pieces(body, predicate, false)
  if not cut.found {
    return (head: [], rest: body, found: false)
  }
  cut
}
