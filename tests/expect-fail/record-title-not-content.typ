// EXPECT: slide-record: title must be content or none; got "Title".
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], title: "Title", level: 2)
