// EXPECT: expand: context-slide result must be content; got "x".
#import "../../src/core/expand.typ": expand
#import "../../src/core/steps.typ": context-slide
#let _ = expand([#context-slide((index, total) => "x")], body => body)
