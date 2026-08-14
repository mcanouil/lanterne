// EXPECT: deck: info.author must be a string or an array of strings; got 1.
#import "../../src/render/deck.typ": deck
#let _ = deck([a], info: (author: 1))
