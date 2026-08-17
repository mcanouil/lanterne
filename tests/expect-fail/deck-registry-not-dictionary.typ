// EXPECT: deck: registry must be a registry from register-container, or none;
// EXPECT: got "none".
#import "../../src/render/deck.typ": deck

#show: deck.with(registry: "none")

== One
a
