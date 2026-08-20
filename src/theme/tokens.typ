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
///! The rule governs a milestone rather than a single commit. A name may arrive
///! one branch ahead of its reader when both land in the same stack, since the
///! alternative is one branch nobody can review; it may never arrive ahead of
///! the milestone that reads it. `accent`, `accent-fg`, `muted`, `border`,
///! `gutter`, `header-height`, `footer-height` and `stroke-width` are read by
///! the renderer slots, and are the eight names currently in that position.
///!
///! Two keys are reserved rather than canonical, and neither is a token.
///!
///! `extra` is the one key whose contents are not validated. Without it,
///! strict validation would leave a user defined element nowhere to keep its
///! own tokens, and the strictness everywhere else is the point: a mistyped
///! token name that is quietly ignored is how a theme rots.
///!
///! `slots` holds a theme's renderers, and its contents are validated against
///! the five names specification 5.2 fixes. It is validated where `extra` is
///! not because that set is a frozen contract: a name outside it is a renderer
///! nothing will ever call, so accepting one would store a slot that silently
///! does nothing.

#import "../utils/errors.typ": fail-enum, fail-type

/// The renderer slots a theme may supply, in the order specification 5.2 names
/// them.
///
/// The set is fixed at five, and expanding it is a deliberate versioned
/// decision, so that a theme stays cheap to maintain across releases. Two of
/// them compose a whole page and three fill a region of one.
/// @category theme
#let SLOT-NAMES = (
  "render-title-slide",
  "render-section-slide",
  "render-header",
  "render-footer",
  "render-progress",
)

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

#let _is-colour(value) = type(value) == color

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

// A region's height, the space between regions and a rule's thickness are all
// geometry that cannot run backwards, so a negative value describes nothing.
// Zero is accepted, since a theme suppresses a region or a rule by giving it
// none of either.
//
// The two components are read separately rather than compared as a whole,
// because Typst refuses to compare a length carrying both an absolute and a
// relative part: `2cm - 1em >= 0pt` raises `cannot compare 2cm + -1em with
// 0pt`. Comparing the whole would therefore replace this message with Typst's
// own on exactly the values this rule exists to reject.
#let _is-non-negative-length(value) = {
  type(value) == length and value.em >= 0.0 and value.abs >= 0pt
}

// Name, default and rule together, so a default cannot drift away from the
// rule that governs it. `expected` completes "<name> must be ...".
#let _SPEC = (
  bg: (default: white, expected: "a colour", ok: _is-colour),
  fg: (default: rgb("#111111"), expected: "a colour", ok: _is-colour),
  accent: (default: rgb("#1f5fa9"), expected: "a colour", ok: _is-colour),
  accent-fg: (default: white, expected: "a colour", ok: _is-colour),
  muted: (default: rgb("#6b6b76"), expected: "a colour", ok: _is-colour),
  border: (default: rgb("#d8d8e0"), expected: "a colour", ok: _is-colour),
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
  gutter: (
    default: 0.6cm,
    expected: "a non-negative length in both its absolute and relative parts",
    ok: _is-non-negative-length,
  ),
  header-height: (
    default: 2cm,
    expected: "a non-negative length in both its absolute and relative parts",
    ok: _is-non-negative-length,
  ),
  footer-height: (
    default: 1cm,
    expected: "a non-negative length in both its absolute and relative parts",
    ok: _is-non-negative-length,
  ),
  stroke-width: (
    default: 1pt,
    expected: "a non-negative length in both its absolute and relative parts",
    ok: _is-non-negative-length,
  ),
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
  // Seeded empty rather than left out, so a renderer reads `tokens.slots`
  // without first asking whether the theme has any.
  tokens.insert("slots", (:))
  tokens
}

/// Panic unless `slots` is a dictionary of canonical slot names holding
/// functions.
///
/// `name` completes every message this raises, so the base of a merge is
/// reported as `base.slots` and an override as `slots`, naming the half of the
/// call the bad key came from. That distinction is the point of re-validating a
/// base: a base built by hand is the one case where the author cannot assume
/// the fault is in the overrides they just wrote.
///
/// An unknown name is refused rather than stored. The renderer calls the five
/// it knows, so a sixth would be a function a theme author wrote, a theme
/// carried, and nothing ever ran.
///
/// A slot's arity and its return value are not checked here, and the arity
/// cannot be: Typst exposes nothing of a closure's parameters. A slot is called
/// with the named arguments `info`, `tokens` and `state` and returns content,
/// and both are enforced at the call site that composes a page.
/// @category theme
#let check-slots(slots, scope, name: "slots") = {
  if type(slots) != dictionary {
    fail-type(scope, name, slots, "a dictionary")
  }
  for (slot, value) in slots {
    if slot not in SLOT-NAMES {
      fail-enum(scope, name + " key", slot, SLOT-NAMES, hint: "The set of five is fixed")
    }
    // `none` is how an override clears a slot a theme merged in, so it is
    // accepted here and removed by the merge rather than stored.
    if value != none and type(value) != function {
      fail-type(scope, name + "." + slot, value, "a function or none")
    }
  }
}

/// Panic unless `name` is a canonical token holding a value of the right shape.
///
/// Neither reserved key is a token, so `extra` and `slots` are both reported
/// here as unknown names. `extra` is unvalidated by design, and `slots` is
/// validated by `check-slots` instead, so whoever merges a theme handles both
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
