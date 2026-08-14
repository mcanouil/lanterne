// EXPECT: slide-record: a level describes a heading, and this slide has no title; got 2.
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], level: 2)
