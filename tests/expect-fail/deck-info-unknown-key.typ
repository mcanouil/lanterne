// The metadata vocabulary carries what the deck sets, and grows with it. An
// unknown key silently sets nothing, which is how a deck rots.
// EXPECT: deck: info key must be one of "title", "author", "date"; got "subject".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], info: (subject: "Slides"))
