///! Sentinel elements used by the traversal.
///!
///! A marker is a `metadata` element carrying a reserved tag. It renders as
///! nothing, survives being nested inside other elements, and is findable by
///! a generic `fields()` walk.

#let _TAG = "lanterne-marker"

/// Kind tag for a pause boundary.
/// @category core
#let MARKER-PAUSE = "pause"

/// Kind tag for per-slide options attached after a heading.
/// @category core
#let MARKER-SLIDE-OPTIONS = "slide-options"

/// Build a marker of the given kind.
/// @category core
/// @returns content
#let marker(kind, payload: (:)) = metadata((
  tag: _TAG,
  kind: kind,
  payload: payload,
))

/// Whether a value is a lanterne marker.
/// @category core
/// @returns bool
#let is-marker(value) = (
  type(value) == content
    and value.func() == metadata
    and type(value.value) == dictionary
    and value.value.at("tag", default: none) == _TAG
)
