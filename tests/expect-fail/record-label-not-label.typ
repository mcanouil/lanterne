// EXPECT: slide-record: label must be a label or none; got "slide".
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], title: [Title], level: 2, label: "slide")
