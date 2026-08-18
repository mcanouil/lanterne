// EXPECT: rebuild: cannot reconstruct element outline with fields ("title",
// EXPECT: "label") on the path to a label a repeated step has to drop.
// EXPECT: Register it with register-container(fn, positional).
#import "../../src/core/walk.typ": rebuild
#let labelled = [#outline(title: [t]) <toc>].children.first()
#let _ = rebuild(labelled, node => node, keep-labels: false)
