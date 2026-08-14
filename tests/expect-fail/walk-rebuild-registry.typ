// EXPECT: rebuild: registry must be a dictionary or none; got 1.
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], node => node, registry: 1)
