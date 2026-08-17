// A handout range is read by the same parser a step range uses, so it fails
// under the name the author called rather than under a range function they
// never invoked.
// EXPECT: deck: handout ends before it starts; got "4-2". Write the lower step
// EXPECT: first, as "2-4".
#import "../../src/render/deck.typ": deck

#show: deck.with(handout: "4-2")

== One
a
