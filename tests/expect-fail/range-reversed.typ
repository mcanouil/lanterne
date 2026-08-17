// EXPECT: t: range ends before it starts; got "4-2". Write the lower step first, as "2-4".
#import "../../src/core/range.typ": parse-range
#let _ = parse-range("4-2", "t")
