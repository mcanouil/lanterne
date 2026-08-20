// Where a title came from is a property of how the slide was written, and the
// renderer cannot work it out afterwards. A heading opening a slide is that
// slide's title and may be taken out of the body; a title passed to `slide(...)`
// is an argument, and that body may carry a heading of its own at the same
// level. The two are written together so neither can be assumed.
// EXPECT: slide-record: a title and its source are written together; got
// EXPECT: [T] and none. Pass title-source alongside title, or neither.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([], title: [T], level: 2)
