// EXPECT: rebuild: subject must be a string naming what the match found; got 1.
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], node => node, subject: 1)
