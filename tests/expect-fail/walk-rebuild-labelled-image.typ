// EXPECT: rebuild: cannot drop the label <shown> from an image on a slide of
// EXPECT: several steps. Move the label onto a figure or a block around the
// EXPECT: image, which can be rebuilt.
#import "../../src/core/walk.typ": rebuild
#let svg-bytes = bytes(
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"></svg>",
)
#let labelled = [#image(svg-bytes, format: "svg") <shown>].children.first()
#let _ = rebuild(labelled, node => node, keep-labels: false)
