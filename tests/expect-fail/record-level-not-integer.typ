// A heading's level starts at 1, so 0 describes no heading Typst can emit.
// EXPECT: slide-record: level must be a positive integer or none; got 0.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], title: [Title], level: 0)
