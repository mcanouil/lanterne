// EXPECT: t: range must be an integer, an array of integers, or a string of the form "2", "2-", "-3" or "2-4"; got "2-4-6".
#import "../../src/core/range.typ": parse-range
#let _ = parse-range("2-4-6", "t")
