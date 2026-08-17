// EXPECT: emit-step: range is required. Write emit-step(range: "2-", body: [...]).
#import "../../src/emit/step.typ": emit-step
#let _ = emit-step(body: [x])
