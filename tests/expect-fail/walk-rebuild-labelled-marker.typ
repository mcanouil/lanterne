// EXPECT: rebuild: cannot keep the label <region> on a pause marker. Put the
// EXPECT: label on the content the marker carries instead.
#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/walk.typ": rebuild
#let labelled = [#marker(MARKER-PAUSE) <region>].children.first()
#let _ = rebuild(labelled, node => [])
