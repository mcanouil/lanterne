// A theme is a validated token dictionary. Two functions build one, and
// nothing else may, so every token dictionary the package handles has been
// through the same per-key validation and no code downstream re-checks what it
// reads.
//
// Typst cannot catch a panic, so the rejecting paths are compiled as their own
// files under tests/expect-fail/.

#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#import "../../src/theme/tokens.typ": default-tokens

// With no overrides, a theme is the defaults.
#assert.eq(theme-tokens(), default-tokens())

// An override replaces one key and leaves every other at its default. The key
// set is asserted alongside, because a merge that dropped a key would satisfy
// the value assertions and fail at the point of use a milestone later.
#let dark = theme-tokens(bg: black, fg: white)
#assert.eq(dark.bg, black)
#assert.eq(dark.fg, white)
#assert.eq(dark.size-base, default-tokens().size-base)
#assert.eq(dark.keys().sorted(), default-tokens().keys().sorted())

// The defaults are untouched by a theme built from them.
#assert.eq(default-tokens().bg, white)

// `extra` takes any keys, and its contents are not validated: a value that
// would be rejected under every canonical rule is kept as it is.
#let custom = theme-tokens(extra: (badge-fill: red, badge-width: 3))
#assert.eq(custom.extra.badge-fill, red)
#assert.eq(custom.extra.badge-width, 3)

// Merging is additive over `extra` rather than replacing it. Replacing would
// mean setting one token of your own silently dropped every other the base
// theme carried, which is the failure a theme author would notice last.
#let merged = theme-merge(custom, (extra: (badge-width: 5, badge-radius: 2pt)))
#assert.eq(merged.extra.badge-fill, red)
#assert.eq(merged.extra.badge-width, 5)
#assert.eq(merged.extra.badge-radius, 2pt)

// `slots` is the second reserved key, and it merges the way `extra` does. A
// theme author overriding one colour of a preset must not silently lose the
// renderers that preset supplied, which is what wholesale replacement would do.
#let header = (info: none, tokens: none, state: none) => [h]
#let footer = (info: none, tokens: none, state: none) => [f]
#let themed = theme-tokens(slots: (render-header: header))
#assert.eq(themed.slots.keys(), ("render-header",))
#assert.eq(themed.slots.render-header, header)

#let both = theme-merge(themed, (slots: (render-footer: footer), bg: black))
#assert.eq(both.slots.render-header, header)
#assert.eq(both.slots.render-footer, footer)
#assert.eq(both.bg, black)

// The last writer wins for a slot, as it does for a token.
#let replaced = theme-merge(themed, (slots: (render-header: footer)))
#assert.eq(replaced.slots.render-header, footer)

// `none` removes a slot rather than storing it, which is what lets a theme take
// a preset's chrome without one of its parts. The key goes, so a renderer that
// asks whether a slot exists gets the right answer.
#assert.eq(theme-merge(both, (slots: (render-footer: none))).slots.keys(), ("render-header",))
#assert.eq(theme-merge(themed, (slots: (render-header: none))).slots, (:))

// Clearing a slot the theme never had is not an error. It says the same thing
// about the result as clearing one it did.
#assert.eq(theme-merge(theme-tokens(), (slots: (render-footer: none))).slots, (:))

// The result of a clearing merge is itself a valid base, which is what makes
// `none` safe to accept in an override and refuse in a base: the merge never
// leaves one behind for the next merge to read.
#assert.eq(theme-merge(theme-merge(both, (slots: (render-footer: none))), (:)).slots.keys(), ("render-header",))

// A theme with no slots carries the key and an empty dictionary, so a renderer
// reads `tokens.slots` without asking whether it exists.
#assert.eq(theme-tokens().slots, (:))

// A canonical token still validates when it arrives through a merge rather
// than through the constructor.
#assert.eq(theme-merge(theme-tokens(), (margin: 1cm)).margin, 1cm)

// Merging nothing changes nothing.
#assert.eq(theme-merge(dark, (:)), dark)

// The result of a merge is itself a valid base, so merges chain and the last
// writer wins.
#assert.eq(theme-merge(theme-merge(dark, (margin: 1cm)), (margin: 3cm)).margin, 3cm)
#assert.eq(theme-merge(theme-merge(dark, (margin: 1cm)), (margin: 3cm)).bg, black)

// The rejecting paths live in tests/expect-fail/theme-*.typ, where each is
// compiled and its message matched. The pair that matters most is
// theme-tokens-unknown-name.typ and theme-merge-unknown-name.typ: the same
// rejection reached through either public function, each naming the function
// the author called rather than the private helper both route through.

theme tests passed.
