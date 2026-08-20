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

#import "../../src/theme/tokens.typ": SLOT-NAMES, check-slots, check-token, default-tokens

#let defaults = default-tokens()

// Every canonical name, and nothing else.
#assert.eq(
  defaults.keys().sorted(),
  (
    "accent",
    "accent-fg",
    "bg",
    "border",
    "dim-opacity",
    "extra",
    "fg",
    "font-base",
    "font-heading",
    "footer-height",
    "gutter",
    "header-height",
    "leading",
    "margin",
    "muted",
    "scale-ratio",
    "size-base",
    "slots",
    "stroke-width",
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
#assert.eq(defaults.accent, rgb("#1f5fa9"))
#assert.eq(defaults.accent-fg, white)
#assert.eq(defaults.muted, rgb("#6b6b76"))
#assert.eq(defaults.border, rgb("#d8d8e0"))
#assert.eq(defaults.gutter, 0.6cm)
#assert.eq(defaults.header-height, 2cm)
#assert.eq(defaults.footer-height, 1cm)
#assert.eq(defaults.stroke-width, 1pt)
#assert.eq(defaults.slots, (:))

// Every default satisfies its own rule. A table of literals and a table of
// rules otherwise drift apart silently, and the default is the value most
// decks will actually carry.
#for (name, value) in defaults {
  if name not in ("extra", "slots") { check-token(name, value, "test") }
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

// Typst also takes a bare coverage-scoped entry, with no list around it.
#check-token("font-base", (name: "Libertinus Serif", covers: "latin-in-cjk"), "test")
#check-token("font-heading", (name: "Libertinus Serif", covers: regex("[0-9]")), "test")
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

// The geometry a region is built from cannot be negative: a band of negative
// height and a rule of negative thickness describe nothing. Zero is accepted,
// since a theme suppresses a region by giving it no height.
#check-token("gutter", 0pt, "test")
#check-token("header-height", 0cm, "test")
#check-token("footer-height", 1em, "test")
#check-token("stroke-width", 0pt, "test")
#check-token("stroke-width", 0.5em, "test")

// A length carrying both an absolute and a relative part cannot be compared
// with `0pt` at all: Typst raises `cannot compare 3pt + -0.5em with 0pt`. The
// rule reads the two components separately, so a mixed length is judged here
// rather than crashing inside a comparison.
#check-token("header-height", 2cm + 1em, "test")

// The four colour tokens the chrome reads take what the other colours take.
#check-token("accent", rgb(10, 20, 30), "test")
#check-token("accent-fg", white, "test")
#check-token("muted", luma(50%), "test")
#check-token("border", black, "test")

// `slots` is validated where `extra` is not: the set of five is a frozen
// contract, so a name outside it is a slot nobody would ever call.
#assert.eq(
  SLOT-NAMES,
  (
    "render-title-slide",
    "render-section-slide",
    "render-header",
    "render-footer",
    "render-progress",
  ),
)
#check-slots((:), "test")
#check-slots((render-header: (info: none, tokens: none, state: none) => []), "test")
#for name in SLOT-NAMES { check-slots(((name): () => []), "test") }

// `slots` is not a token either, so check-token rejects it by name. Asserting
// that positively is impossible, so tests/expect-fail/token-slots-as-name.typ
// pins it beside token-extra-as-name.typ.

// The rejecting paths live in tests/expect-fail/token-*.typ, where each is
// compiled and its message matched. They were comments here until the suite
// existed, which documented the messages and tested nothing: deleting the
// unknown-name branch from check-token left every file in this directory
// passing.

tokens tests passed.
