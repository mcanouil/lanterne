walk-depth-rebuild.typ
// The same bound holds across a rebuild, which is the walk that restarted the
// count at every level before it was fixed.
// EXPECT: walk: content is nested more than 30 levels deep. Flatten the
// EXPECT: nesting on this slide, or raise max-depth.
#import "../../src/core/walk.typ": rebuild
#let nest(k) = {
  let acc = [leaf]
  for _ in range(k) { acc = block(acc) }
  acc
}
#let _ = rebuild(nest(35), node => node)
