// EXPECT: slide-record: title-source must be one of "heading", "value"; got
// EXPECT: "argument".
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([], title: [T], title-source: "argument", level: 2)
