// The container rule covers dictionaries as well as arrays: one sitting
// directly inside another climbs, so nesting made only of dictionaries is
// bounded rather than dying with Typst's own diagnostic, reported from inside
// this package with no source location for the offending content.
// EXPECT: walk: content is nested more than 30 levels deep. Flatten the
// EXPECT: nesting on this slide, or raise max-depth.
#import "../../src/core/walk.typ": has-marker
#let deep(k) = {
  let acc = (:)
  for _ in range(k) { acc = (inner: acc) }
  acc
}
#let _ = has-marker(metadata(deep(40)))
