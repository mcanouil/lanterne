// EXPECT: emit-step: range ends before it starts; got "4-2". Write the lower step first, as "2-4".
#import "../../src/emit/step.typ": emit-step
#let _ = emit-step(range: "4-2", body: [x])
