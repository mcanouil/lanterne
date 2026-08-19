// An option name nothing reads is a silent no-op, which is how a deck rots: the
// author sees no error and no effect.
// EXPECT: slide-record: slide option must be one of "appendix", "smaller", "steps"; got
// EXPECT: "smallr".
#import "../../src/core/record.typ": slide-record
#let _ = slide-record([body], attrs: (smallr: true))
