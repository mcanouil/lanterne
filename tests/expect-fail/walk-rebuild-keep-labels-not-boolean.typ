// EXPECT: rebuild: keep-labels must be a boolean; got "no".
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], node => node, keep-labels: "no")
