// EXPECT: expand: a pause sits inside an element, where the split cannot reach it. Write uncover(...) around the region instead, or move the pause to the slide's top level.
#import "../../src/core/expand.typ": expand
#import "../../src/core/steps.typ": pause
#let _ = expand([#block[#pause]], body => body)
