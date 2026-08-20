// The reserved key holds a theme's renderers, so anything but a dictionary of
// them is refused where it is written.
// EXPECT: theme-tokens: slots must be a dictionary; got 1.
#import "../../src/theme/theme.typ": theme-tokens
#let _ = theme-tokens(slots: 1)
