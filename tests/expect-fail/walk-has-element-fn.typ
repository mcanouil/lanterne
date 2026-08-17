// EXPECT: has-element: fn must be a function; got "heading".
#import "../../src/core/walk.typ": has-element
#let _ = has-element([a], "heading")
