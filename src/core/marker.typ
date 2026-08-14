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

#let _KINDS = (MARKER-PAUSE, MARKER-SLIDE-OPTIONS, MARKER-SLIDE)

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
