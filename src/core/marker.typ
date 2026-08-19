///! Sentinel elements used by the traversal.
///!
///! A marker is a `metadata` element carrying a reserved tag. It renders as
///! nothing, survives being nested inside other elements, and is findable by
///! a generic `fields()` walk.

#import "../utils/elements.typ": is-elem
#import "../utils/errors.typ": fail-enum

#let _TAG = "lanterne-marker"

/// Kind tag for a pause boundary.
/// @category core
#let MARKER-PAUSE = "pause"

/// Kind tag for per-slide options attached after a heading.
/// @category core
#let MARKER-SLIDE-OPTIONS = "slide-options"

/// Kind tag for a slide written out in full rather than opened by a heading.
///
/// Its payload carries the arguments the author gave, which become a slide
/// record once the splitter knows the deck's slide level.
/// @category core
#let MARKER-SLIDE = "slide"

/// Kind tag for the point a deck's appendix opens at.
///
/// It carries no payload: the splitter consumes it as a boundary, and every
/// slide after it is an appendix slide. A switch rather than a per-slide option,
/// because an appendix is a tail of a deck rather than a property one slide at
/// a time.
/// @category core
#let MARKER-APPENDIX = "appendix"

/// Kind tag for a stepped region.
///
/// Its payload carries the spans the region is visible on, the state it takes
/// before them and the state it takes after them, and the body all three apply
/// to.
/// @category core
#let MARKER-STEP = "step"

/// Kind tag for the callback form of a slide.
///
/// Its payload carries a closure, which the step resolution calls with the
/// resolved step index and total. It exists because a marker inside a `context`
/// block is unreachable, so a body that needs the step index has to be given it
/// rather than read it.
/// @category core
#let MARKER-CONTEXT-SLIDE = "context-slide"

#let _KINDS = (
  MARKER-APPENDIX,
  MARKER-PAUSE,
  MARKER-SLIDE-OPTIONS,
  MARKER-SLIDE,
  MARKER-STEP,
  MARKER-CONTEXT-SLIDE,
)

/// Build a marker of the given kind.
/// An unknown kind is rejected here, because a marker no consumer matches
/// renders as nothing and silently costs the slide a step.
/// @category core
/// @returns content
#let marker(kind, payload: (:)) = {
  if kind not in _KINDS {
    fail-enum("marker", "kind", kind, _KINDS)
  }
  metadata((
    tag: _TAG,
    kind: kind,
    payload: payload,
  ))
}

/// Whether a value is a lanterne marker.
/// @category core
/// @returns bool
#let is-marker(value) = (
  is-elem(value, metadata)
    and type(value.value) == dictionary
    and value.value.at("tag", default: none) == _TAG
)
