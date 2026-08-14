// The facade re-exports and never re-implements.
//
// A name reached through lib.typ is asserted to be the same value as the one
// its module exports, so a second implementation cannot appear behind the
// public name without this failing. Compiling the import alone would prove
// only that something of that name exists.

#import "../../lib.typ"
#import "../../src/theme/theme.typ"

#assert.eq(lib.theme-tokens, theme.theme-tokens)
#assert.eq(lib.theme-merge, theme.theme-merge)

// The surface is what the package promises and no more. A module exporting
// something absent here is internal on purpose: `lookup`, `has-marker`,
// `rebuild`, `split-on` and `check-token` are all reachable from src/ and none
// of them is public.
//
// `register-container` is absent for a sharper reason than the rest. It builds
// a registry value, and `rebuild` is the only function that reads one, so
// exporting it would promise a capability with no public way to spend it. It
// arrives with the deck function that takes a registry.
#assert.eq(dictionary(lib).keys().sorted(), ("theme-merge", "theme-tokens"))

// The facade is used as a wildcard import, which is the form every deck and
// every example takes.
#import "../../lib.typ": *
#assert.eq(theme-tokens().bg, white)
#assert.eq(theme-merge(theme-tokens(), (margin: 1cm)).margin, 1cm)

lib tests passed.
