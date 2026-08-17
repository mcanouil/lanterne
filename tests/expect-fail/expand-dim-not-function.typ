// EXPECT: expand: dim must be a function rendering the dimmed state; got "dim".
#import "../../src/core/expand.typ": expand
#let _ = expand([a], "dim")
