///! Generic content traversal.
///!
///! Detection walks `fields()` recursively: a marker nested in any element,
///! registered or not, is found, so long as it is reachable through
///! `fields()`. Reconstruction is not generic, because
///! `(node.func())(..node.fields())` panics for all but a handful of
///! elements, so it is driven by the registry and fails loudly when an
///! element carrying a marker has no entry. Detection reaching everything
///! `fields()` exposes, and reconstruction failing loudly, is what keeps a
///! marker from being silently lost.
///!
///! One shape is not reachable. A `context` block reports no fields at all
///! until layout resolves it, so `(context [#pause]).fields()` is `(:)` and
///! nothing inside it can be seen. Markers held in a closure or in a
///! dictionary-valued field are invisible for the same reason. A step
///! boundary written inside `context` is therefore lost, and `#pause` has to
///! be written outside the context block.

#import "marker.typ": is-marker
#import "registry.typ": lookup
#import "../utils/errors.typ": fail, fail-type

// Typst aborts with `maximum function call depth exceeded` somewhere between
// 25 and 30 nesting levels, from inside library internals and with no source
// location for the offending content. The walk stops just short of that so
// the failure names the cause instead.
#let _MAX-DEPTH = 24

#let _has-marker(node, depth) = {
  if is-marker(node) { return true }
  if depth > _MAX-DEPTH {
    fail(
      "walk",
      "content is nested more than " + str(_MAX-DEPTH) + " levels deep",
      hint: "Typst cannot recurse further; flatten the nesting on this slide.",
    )
  }
  if type(node) == array {
    return node.any(child => _has-marker(child, depth + 1))
  }
  if type(node) != content { return false }
  for (_, value) in node.fields() {
    if _has-marker(value, depth + 1) { return true }
  }
  false
}

/// Whether `node` contains a lanterne marker at any depth.
///
/// `node` need not be content: it is called on every field value found while
/// walking `fields()`, which includes arrays of content and arrays of arrays
/// (a grid's children, or a matrix's rows) as well as plain values such as
/// lengths and dictionaries that never contain a marker.
///
/// Content inside a `context` block is not reachable through `fields()` and
/// is not searched. See the module header.
/// @category core
/// @returns bool
#let has-marker(node) = _has-marker(node, 0)

// The fields an element gains when it is synthesised inside a show rule and
// which are not constructor parameters. Only these: `scope` on a figure and
// `theme` on a raw are parameters, and dropping either of those produces a
// rebuild that no longer compares equal.
#let _SYNTHESISED = (
  (fn: figure, names: ("counter",)),
  (fn: raw, names: ("lines",)),
  (fn: figure.caption, names: ("kind", "supplement", "numbering", "counter")),
  (fn: ref, names: ("citation", "element")),
)

#let _strip-synthesised(fn, fields) = {
  let stripped = fields
  for rule in _SYNTHESISED {
    if fn == rule.fn {
      for name in rule.names {
        let _ = stripped.remove(name, default: none)
      }
    }
  }
  stripped
}

// The recursion. Arguments are validated once by `rebuild` rather than on
// every node, so this takes `registry` positionally and assumes it is valid.
#let _rebuild(node, transform, registry) = {
  if is-marker(node) { return transform(node) }
  if (type(node) == content and node.func() == image) { return node }
  if not has-marker(node) { return node }
  if type(node) == array {
    return node.map(item => _rebuild(item, transform, registry))
  }

  let fn = node.func()
  let entry = lookup(fn, registry: registry)
  if entry == none {
    // `repr` is not injective over element functions, so the name alone can
    // be ambiguous: table.header and grid.header both repr as "header". The
    // field names distinguish them well enough to act on.
    fail(
      "rebuild",
      "cannot reconstruct element "
        + repr(fn)
        + " with fields "
        + repr(node.fields().keys())
        + " containing a step marker",
      hint: "Register it with register-container(fn, positional).",
    )
  }

  let fields = _strip-synthesised(fn, node.fields())
  let element-label = fields.remove("label", default: none)

  // An optional positional parameter that was never set is absent from
  // fields(), and Typst binds the positional arguments that remain by type,
  // so `align[x]` rebuilds from its body alone.
  let positional = entry.positional.filter(name => name in fields)

  let named = (:)
  for (name, value) in fields {
    if not positional.contains(name) {
      named.insert(name, _rebuild(value, transform, registry))
    }
  }
  let values = positional.map(name => (
    _rebuild(fields.at(name), transform, registry)
  ))

  // A variadic container holds its children in one field that has itself to
  // be spread into separate arguments. A sequence takes its children whole.
  let arguments = if (entry.spread and values.len() == 1) {
    values.first()
  } else {
    values
  }

  let rebuilt = fn(..named, ..arguments)
  if element-label == none { rebuilt } else { [#rebuilt#element-label] }
}

/// Rebuild `node`, applying `transform` to every marker it contains.
///
/// A subtree holding no marker is returned as it is, so the only elements
/// reconstructed are those on the path to a marker. Reconstruction reads the
/// positional fields of the element from the registry, since spreading
/// `fields()` supplies named arguments only and most constructors take their
/// principal parameter positionally.
///
/// Three concerns are cross-cutting rather than per element. A `label` is not
/// a constructor parameter, so it is stripped before the fields are spread
/// and reattached by markup concatenation afterwards. The fields an element
/// gains inside a show rule are dropped. An image is an opaque leaf: its
/// equality is instance identity, so no reconstruction of one can equal the
/// original and it is handed back untouched.
///
/// An element that carries a marker and has no registry entry is a hard
/// error. A deck that silently lost a step boundary is worse than one that
/// failed to build, and the panic names the element and the remedy.
///
/// Like `has-marker`, `node` need not be content: the walk calls this on every
/// field value, and anything holding no marker is handed straight back.
/// @category core
/// @returns content, or the value given when it holds no marker
#let rebuild(node, transform, registry: none) = {
  if type(transform) != function {
    fail-type("rebuild", "transform", transform, "a function")
  }
  if (registry != none and type(registry) != dictionary) {
    fail-type("rebuild", "registry", registry, "a dictionary or none")
  }
  _rebuild(node, transform, registry)
}
