///! Which fields of an element must be handed back positionally.
///!
///! Spreading `node.fields()` supplies named arguments only, but most Typst
///! constructors take their content positionally, so the plain round trip
///! `(node.func())(..node.fields())` panics for all but a handful of
///! elements. The rebuild rule that does hold passes the fields named here
///! positionally, in declaration order, and the rest by name.
///!
///! This registry is the data for that rule. It does not rebuild anything;
///! the shared rebuild helper is separate. An element absent from the
///! registry has no positional fields, which is correct for the six elements
///! that survive the plain spread.
///!
///! The entry set is transcribed from docs/notes/roundtrip-findings.md, where
///! every entry was verified against typst 0.15.1. Read that note before
///! changing anything here, and re-run tests/unit/test-roundtrip.typ after a
///! Typst upgrade.

#import "../utils/errors.typ": fail, fail-type

// Element functions with no public binding, obtained from a sample value.
#let _SEQUENCE = [*a* b].func()
#let _STYLED = text(size: 12pt)[x].func()

// `repr` is not injective over element functions: list.item and enum.item
// both render as "item", as do table.cell and grid.cell. Dictionary keys must
// be strings, so entries are bucketed by repr and disambiguated by comparing
// the function itself, which does distinguish them.
#let _put(registry, fn, entry) = {
  let key = repr(fn)
  let bucket = registry.at(key, default: ()).filter(e => e.fn != fn)
  let updated = registry
  updated.insert(key, bucket + ((fn: fn, entry: entry),))
  updated
}

#let _get(registry, fn) = {
  let found = registry.at(repr(fn), default: ()).filter(e => e.fn == fn)
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
      list.item, enum.item,
      footnote, par, quote, pad, hide,
      underline, overline, strike, highlight, smallcaps,
      sub, super, repeat,
      figure.caption, table.cell, grid.cell,
      math.equation,
    ),
    positional: ("body",),
  ),
  (fns: (text, raw), positional: ("text",)),
  (fns: (metadata,), positional: ("value",)),
  (fns: (h, v), positional: ("amount",)),
  (fns: (ref,), positional: ("target",)),
  (fns: (cite,), positional: ("key",)),
  (fns: (_SEQUENCE,), positional: ("children",)),
  (fns: (align, place), positional: ("alignment", "body")),
  (fns: (columns,), positional: ("count", "body")),
  (fns: (terms.item,), positional: ("term", "description")),
  (fns: (_STYLED,), positional: ("child", "styles")),
  (fns: (link,), positional: ("dest", "body")),
  (
    fns: (list, enum, grid, stack, table, terms),
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
      registry = _put(registry, fn, entry)
    }
  }
  registry
}

/// The entries verified in docs/notes/roundtrip-findings.md, as the base
/// registry that `register-container` extends and `lookup` reads by default.
/// @category core
/// @returns dictionary
#let builtin-registry() = _BUILTIN

/// Record the positional fields of an element, returning a new registry.
///
/// The result is a value, not an update to document state, so it has to be
/// threaded through the deck configuration to take effect. Pass `registry` to
/// chain registrations; the default extends the built in set. Registering an
/// element twice replaces the earlier entry.
///
/// `spread` marks a variadic container whose single positional field holds an
/// array that must be spread into separate arguments.
/// @category core
/// @returns dictionary
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
  _put(base, fn, (positional: positional, spread: spread))
}

/// The entry for an element function, or `none` when it has no positional
/// fields.
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
  _get(if registry == none { _BUILTIN } else { registry }, fn)
}
