///! The step surface: the calls an author writes to make content appear.
///!
///! One primitive. `step(range, body, before: ..., after: ...)` carries its
///! spans and two states, and `uncover`, `only`, `dim` and `focus` are that
///! primitive with the states set. Beamer needs three primitives for the same
///! job; the states are what collapse them into one.
///!
///! Three zones, not two. A step inside the spans renders visible, always. A
///! step below the lowest step any span mentions renders the `before` state.
///! Every other step renders the `after` state, which is what makes the zones
///! total for a span set such as `(1, 3, 5)`.
///!
///! `#pause` is sugar and is consumed by the expansion rather than resolved
///! here: it cuts the slide body, and each segment after it is wrapped in an
///! open ended `uncover`, so the author never writes an index.
///!
///! Every function takes a `scope`, because the machine surface in `src/emit/`
///! delegates to these and an author told to fix a call they never wrote is
///! sent to the wrong line. It is the arrangement `slides` already uses.
///!
///! A heading inside a stepped region is refused here, at the call the author
///! wrote, per specification 4.4. An outline entry and a PDF bookmark that
///! appear and disappear between steps are worse than a compile error. The
///! refusal runs through `has-element`, whose own depth guard reports under
///! the fixed scope `"walk"` rather than under the caller's scope, so a region
///! nested past `walk.MAX-DEPTH` levels deep reports `walk: content is nested
///! more than 30 levels deep` instead of naming `step`, `uncover`, `dim`,
///! `focus` or `only`. That guard is not this module's to rename.

#import "marker.typ": MARKER-CONTEXT-SLIDE, MARKER-PAUSE, MARKER-STEP, marker
#import "range.typ": parse-range
#import "walk.typ": has-element
#import "../utils/errors.typ": fail, fail-enum, fail-type

/// The states a stepped region can take.
///
/// `visible` is the body. `hidden` reserves its space with `hide`. `removed` is
/// not laid out at all. `dimmed` renders at the `dim-opacity` token's value.
/// @category core
#let STATES = ("visible", "hidden", "dimmed", "removed")

/// A region of a slide that is visible on some steps and not on others.
///
/// `range` is an integer, an array of integers, or a string such as `"2"`,
/// `"2-"`, `"-3"` or `"2-4"`, one based. `before` is the state the region takes
/// on every step below the lowest one the range mentions, and `after` is the
/// state it takes on every step above the range. Inside the range it is always
/// visible.
///
/// A heading in `body` is refused: specification 4.4 makes it a hard error,
/// because an outline entry that comes and goes between steps is a deck that
/// builds and is wrong.
///
/// `scope` names the caller in any message this raises, since `emit-step` and
/// the four aliases all reach the same validation.
/// @category step
/// @returns content
#let step(range, body, before: "hidden", after: "visible", scope: "step") = {
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  if before not in STATES {
    fail-enum(scope, "before", before, STATES)
  }
  if after not in STATES {
    fail-enum(scope, "after", after, STATES)
  }
  if has-element(body, heading) {
    fail(
      scope,
      "a heading cannot sit inside a stepped region",
      hint: "Move the heading out of the region, or raise slide-level so it opens a slide of its own.",
    )
  }
  marker(
    MARKER-STEP,
    payload: (
      spans: parse-range(range, scope),
      before: before,
      after: after,
      body: body,
    ),
  )
}

/// Hidden before its range and visible from there on.
///
/// A closed upper bound such as `"2-4"` still raises the slide's step count to
/// its end, per the counting rule the whole engine follows, even though `after`
/// is `"visible"` and the content already shows past the range's own steps: the
/// slide gains steps that all render identically. Use `only` if you want the
/// content to disappear again, or `step(..., after: "hidden")` if you want it
/// to hide.
/// @category step
/// @returns content
#let uncover(range, body, scope: "uncover") = step(
  range,
  body,
  before: "hidden",
  after: "visible",
  scope: scope,
)

/// Laid out on the steps in its range and on no others.
/// @category step
/// @returns content
#let only(range, body, scope: "only") = step(
  range,
  body,
  before: "removed",
  after: "removed",
  scope: scope,
)

/// Dimmed before its range and full strength from there on, so upcoming content
/// is greyed and brightens as it is reached.
///
/// Typst 0.15 has no content opacity, so the renderer dims by setting the text
/// fill from the `dim-opacity` token. An image, an explicit fill and a stroke
/// inside a dimmed region therefore do not dim.
///
/// A closed upper bound such as `"2-4"` still raises the slide's step count to
/// its end, per the counting rule the whole engine follows, even though `after`
/// is `"visible"` and the content is already at full strength past the range's
/// own steps: the slide gains steps that all render identically. Use `focus`
/// if you want the content to dim again once the range ends, or
/// `step(..., after: "dimmed")` for the same effect with `focus`'s other side
/// left alone.
/// @category step
/// @returns content
#let dim(range, body, scope: "dim") = step(
  range,
  body,
  before: "dimmed",
  after: "visible",
  scope: scope,
)

/// Dimmed outside its range, so one region is emphasised at a time and the rest
/// stay legible. The dimming carries the same limitation as `dim`.
/// @category step
/// @returns content
#let focus(range, body, scope: "focus") = step(
  range,
  body,
  before: "dimmed",
  after: "dimmed",
  scope: scope,
)

/// A step boundary, written `#pause`.
///
/// Content, not a function, so it reads as the specification writes it. The
/// expansion cuts the slide body here and wraps everything after it in an open
/// ended `uncover`, so an author who writes pauses never writes an index.
///
/// It has to be a top level child of the slide body. One nested inside a
/// container is refused by the expansion rather than silently rendering as
/// nothing.
/// @category step
#let pause = marker(MARKER-PAUSE)

/// A slide body that is handed the resolved step index and total.
///
/// `fn` is called as `fn(index, total)` on every step, with one based `index`.
/// This is the only supported way to write step dependent content inside
/// `context`, per specification 4.5, because a marker inside a `context` block
/// reports no fields until layout resolves it and is therefore invisible to the
/// traversal.
///
/// A range written inside the callback cannot be counted, for the same reason:
/// what the callback returns does not exist when the step count is computed.
/// Raise the count with the slide's `steps` option when the callback needs more
/// steps than the rest of the body advertises.
/// @category step
/// @returns content
#let context-slide(fn, scope: "context-slide") = {
  if type(fn) != function {
    fail-type(scope, "fn", fn, "a function taking the step index and total")
  }
  marker(MARKER-CONTEXT-SLIDE, payload: (fn: fn))
}
