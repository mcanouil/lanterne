///! Building and merging validated token dictionaries.
///!
///! These two functions are the only way a token dictionary is built, so every
///! theme the package handles has been through the same per-key validation and
///! nothing downstream re-checks what it reads.
///!
///! A theme is a value rather than document state, for the reason ARCHITECTURE
///! records for the container registry: `state` is context dependent, so a
///! theme held in one could only be read inside a `context` block, and it is
///! document-order dependent, so the same slide could resolve a different
///! theme depending on where it sits in the deck.

#import "tokens.typ": check-slots, check-token, default-tokens
#import "../utils/errors.typ": fail, fail-type, repr-each

// The merge itself, taking the scope it reports under. Both public functions
// route through this, so a value rejected on behalf of `theme-tokens` names
// `theme-tokens` rather than the helper the author never called.
#let _merge(base, overrides, scope) = {
  if type(base) != dictionary {
    fail-type(scope, "base", base, "a token dictionary")
  }
  if type(overrides) != dictionary {
    fail-type(scope, "overrides", overrides, "a dictionary of token values")
  }

  let missing = default-tokens().keys().filter(name => name not in base)
  if missing.len() > 0 {
    fail(
      scope,
      // `repr` of an array this long pretty-prints over a dozen lines, which
      // buries the hint. The shared list helper keeps the message to one.
      "base is missing " + repr-each(missing),
      hint: "Build a base with theme-tokens rather than by hand",
    )
  }
  // `base` is validated rather than trusted. It is usually the output of this
  // same function, in which case this costs one pass over twenty keys; when it
  // is not, this is the only place the mistake can still be reported by name.
  //
  // Both reserved keys are exempt, because neither is a token and
  // `check-token` reports either as an unknown name. Leaving `slots` in this
  // loop would fail every theme the package builds, including the defaults.
  for (name, value) in base {
    if name not in ("extra", "slots") { check-token(name, value, scope) }
  }
  if type(base.extra) != dictionary {
    fail-type(scope, "base.extra", base.extra, "a dictionary")
  }
  check-slots(base.slots, scope, name: "base.slots")

  let merged = base
  for (name, value) in overrides {
    if name in ("extra", "slots") {
      // Both reserved keys merge key by key rather than being replaced.
      // Replacing wholesale would mean that setting one token of your own, or
      // overriding one colour of a preset, silently dropped every other token
      // or renderer that theme carried, which is the failure a theme author
      // notices last.
      //
      // Validated before the merge, so a bad override reports the package's
      // own message rather than Typst's on `dictionary + 1`.
      if name == "extra" {
        if type(value) != dictionary {
          fail-type(scope, "extra", value, "a dictionary")
        }
      } else {
        check-slots(value, scope)
      }
      merged.insert(name, merged.at(name) + value)
    } else {
      check-token(name, value, scope)
      merged.insert(name, value)
    }
  }
  merged
}

/// Merge `overrides` into `base`, validating every key of both.
///
/// `extra` merges key by key rather than replacing wholesale, so setting one
/// token of your own leaves the rest of the base theme's in place.
/// @category theme
/// @stability experimental
/// @param base A complete token dictionary rather than any subset. A partial one would flow downstream and fail where it is read, naming a missing key, rather than here, naming the theme that lacks it.
/// @param overrides The tokens to apply over it.
/// @returns dictionary
/// @examples-static
/// ```typst
/// #let dark = theme-merge(base, (bg: rgb("#1c1c22"), fg: white))
/// ```
#let theme-merge(base, overrides) = _merge(base, overrides, "theme-merge")

/// A theme: the canonical defaults with the named overrides applied.
///
/// Named arguments only. A positional argument carries no token name to
/// validate against, so it is rejected rather than ignored.
///
/// An unrecognised token name is an error rather than a silent no-op, because
/// a theme that ignores a typo rots quietly. The one exception is `extra`,
/// which exists so that a token of your own has somewhere to live.
/// @category theme
/// @stability experimental
/// @param ..overrides The tokens to set, named only.
/// @returns dictionary
/// @examples-static
/// ```typst
/// #let base = theme-tokens(bg: rgb("#fbfbfd"), fg: rgb("#1c1c22"))
/// ```
#let theme-tokens(..overrides) = {
  let scope = "theme-tokens"
  if overrides.pos().len() > 0 {
    fail(
      scope,
      "takes named arguments only; got " + repr(overrides.pos()),
      hint: "Write theme-tokens(bg: white)",
    )
  }
  _merge(default-tokens(), overrides.named(), scope)
}
