///! The token vocabulary: canonical names, defaults and per-key validation.
///!
///! Flat by design. The colour, typography and geometry groupings are
///! documentation rather than structure, so a theme merges without recursion
///! and a generated theme is one dictionary literal a filter can emit.
///!
///! The vocabulary carries only the tokens something in the package reads.
///! Growing it is additive: an unknown name is an error today and gains a
///! default when the code that reads it lands, so a theme written against this
///! file keeps working as the vocabulary grows. Shipping the names nothing
///! reads yet would validate and store values no code consults, and leave the
///! reader unable to tell which of them mean anything.
///!
///! `extra` is the one key whose contents are not validated. Without it,
///! strict validation would leave a user defined element nowhere to keep its
///! own tokens, and the strictness everywhere else is the point: a mistyped
///! token name that is quietly ignored is how a theme rots.

#import "../utils/errors.typ": fail-enum, fail-type

#let _WEIGHTS = (
  "thin",
  "extralight",
  "light",
  "regular",
  "medium",
  "semibold",
  "bold",
  "extrabold",
  "black",
)

// Typst takes a font family as a name or as a coverage-scoped dictionary,
// either on its own or inside a fallback list. The dictionary form is how a
// deck mixes scripts, sending some codepoints to one family and the rest to
// another, so rejecting it would make this rule stricter than the thing it
// validates for. `covers` is left to Typst, which reports its own forms better
// than a copy of them here would.
//
// An empty list is rejected because it selects nothing at all rather than
// falling back, and a dictionary with no `name` for the same reason.
#let _is-family(entry) = {
  if type(entry) == str { return true }
  type(entry) == dictionary and type(entry.at("name", default: none)) == str
}

#let _is-font(value) = {
  // A single family, as a name or as a coverage-scoped entry, needs no list
  // around it, and Typst takes it either way.
  if type(value) != array { return _is-family(value) }
  value.len() > 0 and value.all(_is-family)
}

#let _is-weight(value) = {
  if type(value) == str { return _WEIGHTS.contains(value) }
  type(value) == int and value >= 100 and value <= 900
}

// Below 1 the headings come out smaller than the body text, which is a theme
// asking for the opposite of what a scale is for.
#let _is-scale(value) = type(value) in (int, float) and value >= 1

// A base size written in `em` would be relative to itself, so it is the one
// length in the vocabulary that has to be absolute. `length.em` is the em
// component as a float, so a pure absolute length reports 0.0, and the
// comparison against `0pt` is only reached once that holds.
#let _is-base-size(value) = type(value) == length and value.em == 0.0 and value > 0pt

// Name, default and rule together, so a default cannot drift away from the
// rule that governs it. `expected` completes "<name> must be ...".
#let _SPEC = (
  bg: (default: white, expected: "a colour", ok: v => type(v) == color),
  fg: (default: rgb("#111111"), expected: "a colour", ok: v => type(v) == color),
  dim-opacity: (
    default: 30%,
    expected: "a ratio between 0% and 100%",
    ok: v => type(v) == ratio and v >= 0% and v <= 100%,
  ),
  font-base: (
    default: "Libertinus Serif",
    expected: "a font family name or coverage-scoped entry, or a non-empty array of them",
    ok: _is-font,
  ),
  font-heading: (
    default: "Libertinus Serif",
    expected: "a font family name or coverage-scoped entry, or a non-empty array of them",
    ok: _is-font,
  ),
  size-base: (
    default: 24pt,
    expected: "a positive absolute length",
    ok: _is-base-size,
  ),
  scale-ratio: (
    default: 1.2,
    expected: "a number of at least 1",
    ok: _is-scale,
  ),
  weight-heading: (
    default: "semibold",
    expected: "an integer from 100 to 900 or a weight name",
    ok: _is-weight,
  ),
  leading: (default: 0.75em, expected: "a length", ok: v => type(v) == length),
  margin: (default: 2cm, expected: "a length", ok: v => type(v) == length),
)

/// The canonical token dictionary, every key at its default.
///
/// The defaults are chosen to resolve on a bare toolchain: `Libertinus Serif`
/// is a font Typst embeds, so a deck that sets no font raises no font warning
/// on a machine with nothing installed.
///
/// `leading` and `margin` accept an `em` length deliberately, since both are
/// naturally expressed against the base size. `size-base` cannot, because an
/// `em` value there would be relative to itself.
/// @category theme
/// @returns dictionary
#let default-tokens() = {
  let tokens = (:)
  for (name, spec) in _SPEC { tokens.insert(name, spec.default) }
  tokens.insert("extra", (:))
  tokens
}

/// Panic unless `name` is a canonical token holding a value of the right shape.
///
/// `extra` is not a token and is reported here as an unknown name: its
/// contents are deliberately unvalidated, so whoever merges a theme handles it
/// before reaching this.
///
/// `scope` names the caller in the message, because a token is only ever
/// validated on behalf of one and the author needs to know which call rejected
/// their value.
/// @category theme
#let check-token(name, value, scope) = {
  let spec = _SPEC.at(name, default: none)
  if spec == none {
    fail-enum(
      scope,
      "token name",
      name,
      _SPEC.keys(),
      hint: "A token of your own belongs in extra",
    )
  }
  if not (spec.ok)(value) {
    fail-type(scope, name, value, spec.expected)
  }
}
