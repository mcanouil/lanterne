///! Building and merging validated token dictionaries.
///!
///! `theme-tokens` and `theme-merge` are the only ways a token dictionary is
///! built, so every theme the package handles has been through the same per-key
///! validation and nothing downstream re-checks what it reads.
///!
///! `resolve-mode` is the third function here and builds nothing. It decides
///! which token dictionary a render reads, given a theme that may be a light
///! and dark pair, and routes what it selects through the same validation. Its
///! one exemption is the defaults, which the package built rather than an
///! author, and which the unit suite already holds to every rule.
///!
///! A theme is a value rather than document state, for the reason ARCHITECTURE
///! records for the container registry: `state` is context dependent, so a
///! theme held in one could only be read inside a `context` block, and it is
///! document-order dependent, so the same slide could resolve a different
///! theme depending on where it sits in the deck.

#import "tokens.typ": check-slots, check-token, default-tokens
#import "../utils/errors.typ": fail, fail-enum, fail-type, repr-each

// The two halves of a pair, in the order a message lists them.
#let _PAIR = ("light", "dark")

// The merge itself, taking the scope it reports under. Both public functions
// route through this, so a value rejected on behalf of `theme-tokens` names
// `theme-tokens` rather than the helper the author never called.
// `name` is what the value being merged into is called where the author wrote
// it. `theme-merge` takes a `base`, and a deck takes a `theme` whose halves are
// `light` and `dark`, so a message naming `base` in a deck would name a
// parameter that call has never had.
#let _merge(base, overrides, scope, name: "base") = {
  if type(base) != dictionary {
    fail-type(scope, name, base, "a token dictionary")
  }
  if type(overrides) != dictionary {
    fail-type(scope, "overrides", overrides, "a dictionary of token values")
  }

  // A pair reaching a merge is the obvious next thing an author tries, and
  // without this it fails as a token dictionary missing all eighteen names,
  // which describes neither the mistake nor the fix. A merge is per half
  // because a token belongs to a half rather than to the pair.
  let halves = _PAIR.filter(half => half in base)
  if halves.len() > 0 {
    fail(
      scope,
      name + " is a light and dark pair, carrying " + repr-each(halves),
      hint: "Merge into each half, as theme-merge(pair.light, ...)",
    )
  }

  let missing = default-tokens().keys().filter(key => key not in base)
  if missing.len() > 0 {
    fail(
      scope,
      // `repr` of an array this long pretty-prints over a dozen lines, which
      // buries the hint. The shared list helper keeps the message to one.
      name + " is missing " + repr-each(missing),
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
  for (key, value) in base {
    if key not in ("extra", "slots") { check-token(key, value, scope) }
  }
  if type(base.extra) != dictionary {
    fail-type(scope, name + ".extra", base.extra, "a dictionary")
  }
  // `clears: false`, because a base is a theme rather than a change to one. A
  // merge never produces a `none` here, since an override that clears removes
  // the key, so one in this position came from a base built by hand.
  check-slots(base.slots, scope, name: name + ".slots", clears: false)

  let merged = base
  for (name, value) in overrides {
    if name == "extra" {
      // Key by key rather than wholesale, so setting one token of your own
      // leaves the rest of the base theme's in place. Validated first, so a bad
      // override reports the package's own message rather than Typst's on
      // `dictionary + 1`.
      //
      // A token of your own may legitimately be `none`, so nothing here reads a
      // value; `extra` stores exactly what it is given.
      if type(value) != dictionary {
        fail-type(scope, "extra", value, "a dictionary")
      }
      merged.insert("extra", merged.extra + value)
    } else if name == "slots" {
      // Key by key for the same reason, so overriding one colour of a preset
      // keeps the renderers that preset supplied.
      //
      // `none` clears a slot instead of storing one. A theme that wants a
      // preset's chrome without one of its parts has no other way to say so,
      // since every value that is not `none` has to be a function. Removing the
      // key rather than storing `none` is what lets a renderer decide what to
      // compose by asking whether a slot is there.
      check-slots(value, scope)
      let combined = merged.slots
      for (slot, own) in value {
        if own == none {
          let _ = combined.remove(slot, default: none)
        } else {
          combined.insert(slot, own)
        }
      }
      merged.insert("slots", combined)
    } else {
      check-token(name, value, scope)
      merged.insert(name, value)
    }
  }
  merged
}

/// What a render reads from a theme that may be a pair: `(tokens, mode)`.
///
/// A theme is either a token dictionary or a dictionary of exactly `light` and
/// `dark`, each of them one. `mode` selects the half, and `tokens` comes back a
/// plain token dictionary either way, so nothing downstream knows a pair
/// existed and no renderer or slot ever receives one.
///
/// The mode comes back too, because the mode a render is *in* is not the mode it
/// was *asked for*. A theme with no halves has one answer, so it resolves to
/// `light` however it was asked, and a slot told otherwise would draw dark
/// chrome over light tokens. One function decides which half renders, so it
/// reports both halves of that decision rather than leaving the second to be
/// derived again by whoever needs it.
///
/// A pair is written literally rather than built by a constructor. There is
/// nothing to validate in the shape itself that this function does not validate
/// where it is used, and a constructor would be a second way to say `(light:
/// ..., dark: ...)`.
///
/// Both halves are validated, not only the half `mode` selects. A deck rendered
/// light would otherwise carry a dark half nobody had checked, and the mistake
/// would surface for whoever first rendered it the other way.
///
/// A mode named against a single token set is not an error. The option says
/// which half to take, and a theme with no halves has one answer.
///
/// `none` is the canonical defaults. They are returned rather than validated,
/// because validation reports what an author wrote and nobody wrote these.
/// @category theme
/// @returns dictionary
#let resolve-mode(theme, mode, scope) = {
  // Before the `none` shortcut, so that a deck naming no theme still hears
  // about a mistyped mode.
  if mode not in _PAIR {
    fail-enum(scope, "theme-mode", mode, _PAIR)
  }
  if theme == none {
    return (tokens: default-tokens(), mode: "light")
  }
  if type(theme) != dictionary {
    fail-type(scope, "theme", theme, "a token dictionary, a light and dark pair, or none")
  }
  // A dictionary carrying either half is a pair, finished or not. Reading an
  // unfinished one as tokens would report `light` as an unknown token name,
  // which names neither the mistake nor the fix.
  let halves = _PAIR.filter(half => half in theme)
  if halves.len() == 0 {
    // A theme with no halves has one answer, and that answer is light whatever
    // was asked for. See the note above on why the mode comes back at all.
    return (tokens: _merge(theme, (:), scope, name: "theme"), mode: "light")
  }
  if halves.len() < _PAIR.len() {
    fail(
      scope,
      "a light and dark pair carries both halves, and this one carries only " + repr-each(halves),
      hint: "Write (light: ..., dark: ...), or one token dictionary",
    )
  }
  let others = theme.keys().filter(name => name not in _PAIR)
  if others.len() > 0 {
    fail(
      scope,
      "a light and dark pair carries no other key, and this one carries " + repr-each(others),
      hint: "Write the token inside each half",
    )
  }
  let resolved = (:)
  for half in _PAIR {
    let value = theme.at(half)
    if type(value) != dictionary {
      fail-type(scope, "theme." + half, value, "a token dictionary")
    }
    resolved.insert(half, _merge(value, (:), scope, name: "theme." + half))
  }
  (tokens: resolved.at(mode), mode: mode)
}

/// Merge `overrides` into `base`, validating every key of both.
///
/// Both reserved keys merge key by key rather than replacing wholesale. Setting
/// one token of your own leaves the rest of the base theme's `extra` in place,
/// and overriding one colour of a theme keeps the renderers it supplied in
/// `slots`.
///
/// A slot set to `none` is cleared rather than stored, and the key is removed,
/// which is how a theme takes another's chrome without one of its parts. A
/// `none` in `base.slots` is refused instead: a base is a theme rather than a
/// change to one.
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
/// a theme that ignores a typo rots quietly.
///
/// Two names are accepted that are not tokens, and they are validated
/// differently. `extra` exists so that a token of your own has somewhere to
/// live, and its contents are not validated at all. `slots` holds a theme's
/// renderers, and its keys are validated against the five names of
/// `SLOT-NAMES`, each holding a function.
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
