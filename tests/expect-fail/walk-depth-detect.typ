walk-depth-detect.typ
// The depth guard replaces Typst's bare recursion error, which reports from
// inside walk.typ and names no content at all.
// EXPECT: walk: content is nested more than 30 levels deep. Flatten the
// EXPECT: nesting on this slide, or raise max-depth.
#import "../../src/core/walk.typ": has-marker
#let nest(k) = {
  let acc = [leaf]
  for _ in range(k) { acc = block(acc) }
  acc
}
#let _ = has-marker(nest(35))
