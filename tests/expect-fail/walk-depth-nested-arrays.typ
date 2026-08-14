walk-depth-nested-arrays.typ
// Depth counts authored nesting levels, so an array reached from a field does
// not climb: a grid's children or a matrix's rows would otherwise cost a level
// the author never wrote. An array directly inside another array is not that
// shape, and without climbing there the walk recurses without bound and dies
// with Typst's own diagnostic, reported from inside this package with no
// source location for the offending content.
// EXPECT: walk: content is nested more than 30 levels deep. Flatten the
// EXPECT: nesting on this slide, or raise max-depth.
#import "../../src/core/walk.typ": has-marker
#let deep(k) = {
  let acc = ()
  for _ in range(k) { acc = (acc,) }
  acc
}
#let _ = has-marker(metadata(deep(40)))
