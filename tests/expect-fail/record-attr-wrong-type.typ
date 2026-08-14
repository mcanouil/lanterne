// EXPECT: slide-record: smaller must be a boolean; got 1.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], attrs: (smaller: 1))
