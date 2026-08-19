///! A slide body becomes one body per step.
///!
///! Four parts, in order. The pause split runs first, so no pause survives into
///! resolution. Counting then reads every marker the walk finds, including one
///! nested inside another marker's payload, so a step inside a step counts.
///! `keep` selects which steps are built. Resolution is one `rebuild` pass per
///! kept step, with a transform that reads each marker and returns the content
///! for that step.
///!
///! `total` is reported whatever `keep` selects, so the callback form is handed
///! the same total on a handout as on the full deck. That is also what makes
///! `handout: true` cheap: a slide of twenty steps builds one body, not twenty.
///!
///! The dim renderer is an argument rather than an option with a default.
///! `src/core/` holds the deck model and reads no theme, and the dimmed state
///! needs the `dim-opacity` and `fg` tokens. A default that quietly failed to
///! dim would pass every equality assertion in the suite and be obvious only on
///! stage.

#import "counters.typ": advance, increments
#import "footnotes.typ": is-entry, placeholder
#import "marker.typ": MARKER-CONTEXT-SLIDE, MARKER-PAUSE, MARKER-STEP, is-marker
#import "range.typ": first-step, in-spans, max-mentioned
#import "split.typ": split-on
#import "steps.typ": uncover
#import "walk.typ": collect-markers, rebuild
#import "../utils/errors.typ": fail, fail-type

#let _kind(node) = if is-marker(node) { node.value.kind } else { none }

#let _is-pause(node) = _kind(node) == MARKER-PAUSE

// The body with its pauses turned into open ended uncovers, and the number of
// pauses that were there.
//
// A pause the split cannot reach is refused. The split examines top level
// children only, so a pause inside a block or a list item produces no boundary
// and would render as nothing at all, silently costing the slide a step.
// `collect-markers` descends further, into every field the walk reaches, so
// its count includes such a pause; the split's count does not, and the two
// disagreeing is exactly that case.
#let _paused(body, scope) = {
  let segments = split-on(body, _is-pause)
  let boundaries = segments.len() - 1
  let reachable = collect-markers(body).filter(_is-pause).len()
  if reachable > boundaries {
    fail(
      scope,
      "a pause sits inside an element, where the split cannot reach it",
      hint: "Write uncover(...) around the region instead, or move the pause to the slide's top level.",
    )
  }
  if boundaries == 0 { return (body: body, pauses: 0) }
  // Segment i is revealed from step i plus one, so the author never writes an
  // index. The heading guard in `uncover` fires here for a heading written
  // after a pause, reported under this scope.
  let built = segments
    .enumerate()
    .map(((index, segment)) => {
      if index == 0 { segment } else { uncover(str(index + 1) + "-", segment, scope: scope) }
    })
    .sum(default: [])
  (body: built, pauses: boundaries)
}

// The state a stepped region takes on `index`. Three zones, per the step
// model: inside the spans it is visible, below the lowest step they mention it
// takes `before`, and above them it takes `after`.
#let _state-at(payload, index) = {
  if in-spans(payload.spans, index) { "visible" } else if index < first-step(payload.spans) {
    payload.before
  } else {
    payload.after
  }
}

// Whether the step being built is the one that keeps the labels of a subtree.
//
// A label may be emitted once, and a slide body is emitted once per step, so
// exactly one step keeps each. It is the first step at which the subtree is
// shown, so a reference lands where the thing it points at first appears. A
// bookmark is not affected either way: one comes from a heading rather than
// from a label.
//
// `laid-out` is the fallback rather than the rule, and it is not the same set:
// a hidden region is laid out and numbers, but pointing a reference at a page
// where its target is invisible is worse than pointing at the page where it
// appears. It matters when a handout renders no step at which the subtree is
// shown, where the alternative is a label that exists nowhere and a reference
// that fails to resolve.
//
// Neither set covers a region that is removed on every rendered step, such as
// an `only` region a handout drops. Its content is never emitted, so its label
// exists nowhere whatever this answers, and a reference to it fails.
#let _keeps-labels(index, shown, laid-out) = {
  if shown.len() > 0 { return index == shown.first() }
  if laid-out.len() > 0 { return index == laid-out.first() }
  true
}

// The content a marker resolves to on `index`, of `total`.
//
// The recursion is deliberate: `rebuild` stops at a marker and does not descend
// into its payload, so a step inside a step is resolved by this call and not by
// the pass that reached it. Innermost first, therefore, and the states compose.
//
// `shown` and `laid-out` are the rendered steps at which the subtree being
// resolved is shown and at which it is laid out at all. Entering a region
// narrows both, so nesting composes: a region visible on a step where its
// parent is hidden is shown on no step at all.
#let _resolve(node, index, total, dim, registry, scope, shown, laid-out) = {
  let kind = _kind(node)
  if kind == MARKER-CONTEXT-SLIDE {
    // The callback's result goes through the same rebuild pass as the rest of
    // the body, so a marker it returns resolves for the step being rendered
    // rather than passing through untouched. What it returns still cannot
    // contribute to the count: `total` was already fixed by the time this
    // callback ran.
    let built = (node.value.payload.fn)(index, total)
    if type(built) != content {
      fail-type(scope, "context-slide result", built, "content")
    }
    return rebuild(
      built,
      child => _resolve(child, index, total, dim, registry, scope, shown, laid-out),
      keep-labels: _keeps-labels(index, shown, laid-out),
      registry: registry,
    )
  }
  if kind != MARKER-STEP {
    // A pause is consumed by `_paused`, and a slide marker and an option marker
    // are consumed by the splitter, so reaching this means one was written
    // somewhere its consumer does not look: inside a container, most likely.
    fail(
      scope,
      "a " + repr(kind) + " marker reached step resolution",
      hint: "A pause, a slide and its options have to be top level children of the body they belong to.",
    )
  }
  let payload = node.value.payload
  let state = _state-at(payload, index)
  // A removed region is not laid out, so its body is never built. Building it
  // anyway would drop labels from content this step does not emit, and would
  // refuse a labelled image that appears on exactly one step and duplicates
  // nowhere.
  //
  // What it would have numbered is advanced in its place, because a hidden
  // region still numbers and a removed one does not, so without this a figure
  // after an `only` region takes a different number on the steps that drop the
  // region. The count comes from the payload as written, so a removed region
  // nested inside another is counted once, by the outer one.
  if state == "removed" { return advance(increments(payload.body)) }

  // The region's own reach, computed before its body is built, because the
  // body has to know which step keeps its labels.
  let inside-shown = shown.filter(step => _state-at(payload, step) in ("visible", "dimmed"))
  let inside-laid-out = laid-out.filter(step => _state-at(payload, step) != "removed")
  let inner = rebuild(
    payload.body,
    child => _resolve(child, index, total, dim, registry, scope, inside-shown, inside-laid-out),
    keep-labels: _keeps-labels(index, inside-shown, inside-laid-out),
    registry: registry,
  )
  if state == "visible" { return inner }
  if state == "hidden" {
    // A footnote inside the region would still make its entry, so the
    // separator appears a step early. Each is replaced by a hidden mark of the
    // same size carrying the number it would have taken. The pass runs over
    // content that is already resolved, so it meets no marker.
    return hide(rebuild(inner, node => placeholder(), match: is-entry, registry: registry))
  }
  dim(inner)
}

/// Expand a slide body into one body per step.
///
/// `dim` renders the dimmed state and is supplied by the renderer, since this
/// module reads no theme.
///
/// `steps` is the slide's own option: it raises the computed count and never
/// lowers it, because lowering it would hide content the author asked for.
///
/// `keep` selects which steps are built: `none` for all of them, `"final"` for
/// the last one, or an array of spans from `parse-range`. `total` counts every
/// step whatever is selected, so the callback form is handed the same total on a
/// handout as on the full deck.
///
/// `registry` is threaded through to `rebuild`, so a deck that registered its
/// own containers can resolve a step inside one.
/// @category core
/// @returns dictionary
#let expand(body, dim, steps: none, keep: none, registry: none, scope: "expand") = {
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  if type(dim) != function {
    fail-type(scope, "dim", dim, "a function rendering the dimmed state")
  }
  if steps != none and (type(steps) != int or steps < 1) {
    fail-type(scope, "steps", steps, "a positive integer or none")
  }
  if keep != none and keep != "final" and type(keep) != array {
    fail-type(scope, "keep", keep, "none, \"final\", or an array of spans")
  }
  if type(keep) == array {
    for entry in keep {
      if type(entry) != dictionary or "from" not in entry or "to" not in entry {
        fail-type(scope, "a keep entry", entry, "a span from parse-range, a dictionary carrying from and to")
      }
    }
  }

  let paused = _paused(body, scope)
  let mentioned = collect-markers(paused.body)
    .filter(node => _kind(node) == MARKER-STEP)
    .map(node => max-mentioned(node.value.payload.spans))
    .fold(0, calc.max)
  let total = calc.max(paused.pauses + 1, mentioned)
  if steps != none { total = calc.max(total, steps) }

  let indices = range(1, total + 1)
  let selected = if keep == none {
    indices
  } else if keep == "final" {
    (total,)
  } else {
    // A selection that keeps nothing still renders the slide's final step,
    // because a handout setting narrows what is shown and never drops a
    // slide outright.
    let kept = indices.filter(index => in-spans(keep, index))
    if kept.len() == 0 { (total,) } else { kept }
  }

  (
    total: total,
    steps: selected.map(index => (
      index: index,
      body: rebuild(
        paused.body,
        node => _resolve(node, index, total, dim, registry, scope, selected, selected),
        // Whatever sits outside a stepped region is shown on every step that
        // renders, so the first of them keeps its labels. `selected` rather
        // than every step, because a handout renders a subset and a label has
        // to survive on a page that exists.
        keep-labels: _keeps-labels(index, selected, selected),
        registry: registry,
      ),
    )),
  )
}
