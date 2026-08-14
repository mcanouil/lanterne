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
// rejecting paths are compiled as their own files under tests/expect-fail/.

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
// Asserting this positively is impossible, so
// tests/expect-fail/token-extra-as-name.typ pins it.

// The accepting edges of each rule.
#check-token("bg", rgb(10, 20, 30), "test")
#check-token("font-base", ("Libertinus Serif", "New Computer Modern"), "test")

// Typst takes a coverage-scoped entry in a fallback list, which is how a deck
// mixes scripts by sending some codepoints to one family and the rest to
// another. Validation must not be stricter than the thing it validates for.
#check-token(
  "font-base",
  ((name: "Libertinus Serif", covers: regex("[0-9]")), "New Computer Modern"),
  "test",
)
#check-token("font-heading", ((name: "Libertinus Serif", covers: "latin-in-cjk"),), "test")
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

// The rejecting paths live in tests/expect-fail/token-*.typ, where each is
// compiled and its message matched. They were comments here until the suite
// existed, which documented the messages and tested nothing: deleting the
// unknown-name branch from check-token left every file in this directory
// passing.

tokens tests passed.
