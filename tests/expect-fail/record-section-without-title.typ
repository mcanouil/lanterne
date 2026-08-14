// A section slide is a divider, and a divider with nothing on it is a slide the
// author did not ask for.
// EXPECT: slide-record: a section slide must have a title. Pass title, or build
// EXPECT: a content slide instead.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], kind: "section")
