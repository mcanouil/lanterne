// EXPECT: expand: a heading cannot sit inside a stepped region. Move the heading out of the region, or raise slide-level so it opens a slide of its own.
#import "../../src/core/expand.typ": expand
#import "../../src/core/steps.typ": pause
#let _ = expand([
  a #pause
  === t
], body => body)
