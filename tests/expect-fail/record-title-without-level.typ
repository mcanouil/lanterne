// A title is the body of the heading it came from, so it is rendered as that
// heading and cannot be without the level it was written at.
// EXPECT: slide-record: a title needs the level of the heading it came from;
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], title: [Title])
