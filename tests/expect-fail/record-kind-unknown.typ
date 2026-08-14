// EXPECT: slide-record: kind must be one of "section", "content"; got "divider".
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], kind: "divider")
