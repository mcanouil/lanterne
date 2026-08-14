// EXPECT: slide-record: attrs must be a dictionary of slide options; got true.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], attrs: true)
