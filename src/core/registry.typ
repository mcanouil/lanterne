///! Which fields of an element must be handed back positionally.
///!
///! Spreading `node.fields()` supplies named arguments only, but most Typst
///! constructors take their content positionally, so the plain round trip
///! `(node.func())(..node.fields())` panics for all but a handful of
///! elements. The rebuild rule that does hold passes the fields named here
///! positionally, in declaration order, and the rest by name.
///!
///! This registry is the data for that rule. It does not rebuild anything;
///! the shared rebuild helper is separate.
///!
///! A listed field that the instance does not carry is skipped rather than
///! indexed, because positionality is a property of the instance: an unset
///! optional positional parameter is absent from `fields()` altogether. One
///! entry therefore covers both `enum.item(3)[a]` and `enum.item[a]`.
///!
///! An element absent from the registry is unknown, not known to be free of
///! positional fields. Six elements do survive the plain spread, but so does
///! nothing else: the caller decides what to do with an unregistered element
///! rather than assuming an empty positional list is safe.
///!
///! The entry set is transcribed from notes/roundtrip-findings.md, where
///! every entry was verified against typst 0.15.1. Read that note before
///! changing anything here, and re-run tests/unit/test-roundtrip.typ after a
///! Typst upgrade.

#import "../utils/elements.typ": SEQUENCE, STYLED
#import "../utils/errors.typ": fail, fail-type

// `repr` is not injective over element functions: list.item, enum.item and
// terms.item all render as "item", as do table.cell and grid.cell, and
// table.header and grid.header. Dictionary keys must be strings, so entries
// are bucketed by repr and disambiguated by comparing the function itself,
// which does distinguish them.
#let _bucket(registry, fn, scope) = {
  let bucket = registry.at(repr(fn), default: ())
  // Both keys are checked, not just the element function: `_get` reads the
  // recipe unconditionally, so a half-formed entry that cleared this guard
  // died with Typst's own "dictionary does not contain key" instead of the
  // message naming what builds a registry.
  let malformed = e => type(e) != dictionary or "fn" not in e or "entry" not in e
  if type(bucket) != array or bucket.any(malformed) {
    fail-type(scope, "registry", registry, "a registry built by register-container")
  }
  bucket
}

#let _put(registry, fn, entry, scope) = {
  let bucket = _bucket(registry, fn, scope).filter(e => e.fn != fn)
  let updated = registry
  updated.insert(repr(fn), bucket + ((fn: fn, entry: entry),))
  updated
}

#let _get(registry, fn, scope) = {
  let found = _bucket(registry, fn, scope).filter(e => e.fn == fn)
  if found.len() == 0 { none } else { found.first().entry }
}

// The findings table, grouped by shared recipe. `spread` marks a variadic
// container, whose single positional field holds an array that must itself be
// spread into separate arguments. A sequence looks like a container and is
// not one: it takes its children array whole.
#let _GROUPS = (
  (
    fns: (
      block, box, rect, circle, ellipse, square,
      heading, emph, strong, figure,
      list.item,
      footnote, par, quote, pad, hide,
      underline, overline, strike, highlight, smallcaps,
      sub, super, repeat,
      figure.caption, table.cell, grid.cell,
      math.equation,
      scale, move, skew,
      math.lr, math.mid,
    ),
    positional: ("body",),
  ),
  (fns: (rotate,), positional: ("angle", "body")),
  (fns: (enum.item,), positional: ("number", "body")),
  (fns: (math.frac,), positional: ("num", "denom")),
  (fns: (math.attach,), positional: ("base",)),
  (fns: (math.accent,), positional: ("base", "accent")),
  (fns: (math.root,), positional: ("index", "radicand")),
  (fns: (math.class,), positional: ("class", "body")),
  (fns: (math.underbrace,), positional: ("body", "annotation")),
  (fns: (math.op,), positional: ("text",)),
  (fns: (footnote.entry,), positional: ("note",)),
  (fns: (text, raw), positional: ("text",)),
  (fns: (metadata,), positional: ("value",)),
  (fns: (h, v), positional: ("amount",)),
  (fns: (ref,), positional: ("target",)),
  (fns: (cite,), positional: ("key",)),
  (fns: (SEQUENCE,), positional: ("children",)),
  (fns: (align, place), positional: ("alignment", "body")),
  (fns: (columns,), positional: ("count", "body")),
  (fns: (terms.item,), positional: ("term", "description")),
  (fns: (STYLED,), positional: ("child", "styles")),
  (fns: (link,), positional: ("dest", "body")),
  (
    fns: (
      list, enum, grid, stack, table, terms,
      table.header, table.footer, grid.header, grid.footer,
      math.vec, math.cases,
    ),
    positional: ("children",),
    spread: true,
  ),
  (fns: (polygon,), positional: ("vertices",), spread: true),
  (fns: (curve,), positional: ("components",), spread: true),
  (fns: (math.mat,), positional: ("rows",), spread: true),
)

#let _BUILTIN = {
  let registry = (:)
  for group in _GROUPS {
    let entry = (
      positional: group.positional,
      spread: group.at("spread", default: false),
    )
    for fn in group.fns {
      registry = _put(registry, fn, entry, "builtin-registry")
    }
  }
  registry
}

/// The entries verified in notes/roundtrip-findings.md, as the base
/// registry that `register-container` extends and `lookup` reads by default.
/// @category core
/// @returns dictionary
#let builtin-registry() = _BUILTIN

/// Record the positional fields of an element, returning a new registry.
///
/// The result is a value, not an update to document state, so it has to be
/// passed to `deck`'s `registry` option to take effect. Registering the same
/// function twice replaces the earlier entry.
///
/// `notes/roundtrip-findings.md` records the entries verified against Typst
/// 0.15.1. An element absent from the registry is refused rather than guessed
/// at when a step inside it needs reconstructing.
/// @category core
/// @stability stable
/// @param fn The element function, such as a helper of your own or a built in like `rect`.
/// @param positional The field names taken positionally, in declaration order.
/// @param spread Whether the one positional field holds an array that must itself be spread into separate arguments.
/// @param registry A registry to extend, so registrations chain. `none` extends the built in set.
/// @returns dictionary
/// @examples-static
/// ```typst
/// #let registry = register-container(my-box, ("body",))
///
/// #show: deck.with(registry: registry)
/// ```
#let register-container(fn, positional, spread: false, registry: none) = {
  let scope = "register-container"
  if type(fn) != function {
    fail-type(scope, "fn", fn, "a function")
  }
  if type(positional) != array {
    fail-type(scope, "positional", positional, "an array of field names")
  }
  for name in positional {
    if type(name) != str {
      fail-type(scope, "positional entry", name, "a string")
    }
  }
  if type(spread) != bool {
    fail-type(scope, "spread", spread, "a boolean")
  }
  if (registry != none and type(registry) != dictionary) {
    fail-type(scope, "registry", registry, "a dictionary or none")
  }
  if (spread and positional.len() != 1) {
    fail(
      scope,
      "spread needs exactly one positional field; got " + repr(positional),
      hint: "Spread applies to a container whose one field holds an array.",
    )
  }
  let base = if registry == none { _BUILTIN } else { registry }
  _put(base, fn, (positional: positional, spread: spread), scope)
}

/// The entry for an element function, or `none` when it is not registered.
///
/// `none` means unknown. Only the six elements listed in the findings note
/// are known to survive a plain spread of their fields.
///
/// Reads the built in registry unless `registry` is given. The entry is
/// `(positional: array of field names in declaration order, spread: bool)`.
/// @category core
/// @returns dictionary or none
#let lookup(fn, registry: none) = {
  if type(fn) != function {
    fail-type("lookup", "fn", fn, "a function")
  }
  if (registry != none and type(registry) != dictionary) {
    fail-type("lookup", "registry", registry, "a dictionary or none")
  }
  _get(if registry == none { _BUILTIN } else { registry }, fn, "lookup")
}
