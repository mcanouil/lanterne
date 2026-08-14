// The token vocabulary: canonical names, defaults, and a rule per name.
//
// The vocabulary carries only what sub-project A reads, so the name set below
// is a decision rather than a transcription of specification section 5.1.
// Growing it is additive: an unknown name is an error today and gains a
// default when the code that reads it lands, so a theme written against this
// file keeps working as the vocabulary grows. That is why the name set is
// pinned here; shrinking it, or renaming a key, is the breaking change.
//
// Typst cannot catch a panic, so the accepting paths are asserted here and the
// rejecting paths are recorded verbatim at the foot of this file from a
// throwaway compile, the pattern tests/unit/test-walk-rebuild.typ already uses.

#import "../../src/theme/tokens.typ": check-token, default-tokens

#let defaults = default-tokens()

// Every canonical name, and nothing else.
#assert.eq(
  defaults.keys().sorted(),
  (
    "bg",
    "dim-opacity",
    "extra",
    "fg",
    "font-base",
    "font-heading",
    "leading",
    "margin",
    "scale-ratio",
    "size-base",
    "weight-heading",
  ),
)

// The defaults are the values the plan's table records, not merely present.
#assert.eq(defaults.bg, white)
#assert.eq(defaults.fg, rgb("#111111"))
#assert.eq(defaults.dim-opacity, 30%)
#assert.eq(defaults.font-base, "Libertinus Serif")
#assert.eq(defaults.font-heading, "Libertinus Serif")
#assert.eq(defaults.size-base, 24pt)
#assert.eq(defaults.scale-ratio, 1.2)
#assert.eq(defaults.weight-heading, "semibold")
#assert.eq(defaults.leading, 0.75em)
#assert.eq(defaults.margin, 2cm)
#assert.eq(defaults.extra, (:))

// Every default satisfies its own rule. A table of literals and a table of
// rules otherwise drift apart silently, and the default is the value most
// decks will actually carry.
#for (name, value) in defaults {
  if name != "extra" { check-token(name, value, "test") }
}

// `extra` is not a token: its contents are deliberately unvalidated, so it is
// rejected by name here and handled by the caller that merges a theme.
// Asserting this positively is impossible, so it is the recorded message at
// the foot of this file that pins it.

// The accepting edges of each rule.
#check-token("bg", rgb(10, 20, 30), "test")
#check-token("font-base", ("Libertinus Serif", "New Computer Modern"), "test")
#check-token("weight-heading", 100, "test")
#check-token("weight-heading", 900, "test")
#check-token("weight-heading", "black", "test")
#check-token("dim-opacity", 0%, "test")
#check-token("dim-opacity", 100%, "test")
#check-token("scale-ratio", 1, "test")
#check-token("scale-ratio", 2.5, "test")

// A length token takes an `em` value deliberately, since leading and margin
// are naturally written against the base size. The base size itself cannot,
// which is the one asymmetry in the geometry rules.
#check-token("leading", 1em, "test")
#check-token("leading", 12pt, "test")
#check-token("margin", 2em, "test")
#check-token("margin", 10pt, "test")
#check-token("size-base", 1cm, "test")

// The rejecting paths, compiled by hand from .scratch/token-probe.typ and
// recorded verbatim:
//
//   check-token("bgg", white, "theme-tokens")
//     theme-tokens: token name must be one of "bg", "fg", "dim-opacity",
//     "font-base", "font-heading", "size-base", "scale-ratio",
//     "weight-heading", "leading", "margin"; got "bgg". A token of your own
//     belongs in extra.
//
//   check-token("extra", (:), "theme-tokens")
//     the same message, with `got "extra"`. `extra` is reserved rather than
//     canonical, so it is reported as an unknown token name.
//
//   check-token("bg", "red", "theme-tokens")
//     theme-tokens: bg must be a colour; got "red".
//
//   check-token("size-base", 2em, "theme-tokens")
//     theme-tokens: size-base must be a positive absolute length; got 2em.
//
//   check-token("weight-heading", 950, "theme-tokens")
//     theme-tokens: weight-heading must be an integer from 100 to 900 or a
//     weight name; got 950.

tokens tests passed.
