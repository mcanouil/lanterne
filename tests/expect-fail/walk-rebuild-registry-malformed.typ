// The rebuild reads the registry through the registry's own accessor rather
// than through `lookup`, so that the two argument checks in `lookup` do not run
// again at every element reached. The shape check still fires, and it names
// `rebuild` because that is the function the author called.
//
// The expectation stops before the repr of the registry, which is noise here:
// what matters is that the package answers rather than the compiler.
// EXPECT: rebuild: registry must be a registry built by register-container;
#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild(
  block[#marker(MARKER-PAUSE)],
  node => [],
  registry: (repr(block): ((fn: block),)),
)
