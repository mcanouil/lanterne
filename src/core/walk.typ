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
///! A field holding an array or a dictionary is walked through to the values
///! inside it, since `metadata` takes any value and a marker can sit in either.
///!
///! One shape is not reachable. A `context` block reports no fields at all
///! until layout resolves it, so `(context [#pause]).fields()` is `(:)` and
///! nothing inside it can be seen. A marker held in a closure is invisible for
///! the same reason. A step boundary written inside `context` is therefore
///! lost, and `#pause` has to be written outside the context block.
///!
///! Both walks are bounded by `MAX-DEPTH`, so content nested past it fails
///! with a message naming the cause rather than with Typst's own recursion
///! error, which reports from inside this file and names no content at all.
///! The bound is one number for both, because the same rule counts a level in
///! each and neither reaches its own ceiling before the guard fires.
///! `notes/depth-limits.md` records the measurements.

#import "marker.typ": is-marker
#import "registry.typ": _get, builtin-registry
#import "../utils/elements.typ": is-elem
#import "../utils/errors.typ": fail, fail-type

/// The nesting depth the traversal accepts before it gives up.
///
/// Measured, not guessed: `notes/depth-limits.md` records the ceiling
/// Typst's own recursion limit imposes and the headroom this default leaves
/// under it. Raising `max-depth` past that ceiling buys the bare Typst
/// diagnostic rather than a working deck.
///
/// 30 leaves roughly twice the headroom over the deepest generated content
/// measured, 14, and sits below every ceiling in the note, the lowest of which
/// is 37 for detection over a marker at every level. Every measured shape
/// therefore reaches this message rather than Typst's own.
/// @category core
#let MAX-DEPTH = 30

// The depth reached is always the limit plus one, since the guard fires on
// the first level past it, so the message reports the limit and not the
// depth.
#let _depth-error(max-depth) = {
  fail(
    "walk",
    "content is nested more than " + str(max-depth) + " levels deep",
    hint: "Flatten the nesting on this slide, or raise max-depth.",
  )
}

// Depth counts authored nesting levels, so it climbs when the walk descends
// into a content node and not when it walks the array or dictionary a field
// holds. An earlier version counted every `fields()` hop, which cost about
// three per authored level and made the number in the message mean nothing.
// A container reached from a field does not climb, because every ordinary
// element holds its children in one: a grid's cells or a matrix's rows would
// each cost a level the author never wrote. A container sitting directly inside
// another container is not that shape, so it climbs and is checked. Without
// that, nesting that goes through containers alone is unbounded and dies with
// Typst's own diagnostic, reported from inside this package with no source
// location.
#let _container-depth(child, depth) = {
  if type(child) in (array, dictionary) { depth + 1 } else { depth }
}

#let _has-marker(node, depth, max-depth) = {
  if is-marker(node) { return true }
  if type(node) in (array, dictionary) {
    // A dictionary is walked for its values: a key is a string and can hold no
    // marker.
    let children = if type(node) == array { node } else { node.values() }
    return children.any(child => {
      let reached = _container-depth(child, depth)
      if reached > max-depth { _depth-error(max-depth) }
      _has-marker(child, reached, max-depth)
    })
  }
  if type(node) != content { return false }
  if depth > max-depth { _depth-error(max-depth) }
  for (_, value) in node.fields() {
    if _has-marker(value, depth + 1, max-depth) { return true }
  }
  false
}

/// Whether `node` contains a lanterne marker at any depth.
///
/// `node` need not be content: it is called on every field value found while
/// walking `fields()`, which includes arrays of content and arrays of arrays
/// (a grid's children, or a matrix's rows), dictionaries, and plain values such
/// as lengths that can hold no marker at all.
///
/// Content inside a `context` block is not reachable through `fields()` and
/// is not searched. See the module header.
///
/// `max-depth` bounds the authored nesting levels the walk descends before it
/// fails with a message naming the cause. See `MAX-DEPTH`.
/// @category core
/// @returns bool
#let has-marker(node, max-depth: MAX-DEPTH) = {
  if type(max-depth) != int or max-depth < 1 {
    fail-type("has-marker", "max-depth", max-depth, "a positive integer")
  }
  _has-marker(node, 0, max-depth)
}

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

// The recursion, fused: it reports whether a marker was under it as well as
// what it built, so each node is walked once rather than once for every level
// above it. Detection used to run separately at each level, which cost
// (D+1)(D+2)/2 walks over a chain of depth D and, worse, put a detection frame
// on the stack above every rebuild frame.
//
// `found` is what keeps reconstruction narrow: a subtree holding no marker
// hands back the value it was given rather than a rebuilt copy, so an
// unregistered element is an error only when a marker sits under it.
//
// Every field is descended into, including the ones stripped below, so `found`
// means what the separate detection call meant: a marker anywhere `fields()`
// exposes. A marker in a synthesised field is still dropped by the
// reconstruction afterwards, exactly as it was before.
//
// Arguments are validated once by `rebuild`, so the registry arrives resolved
// and is read through the registry's own accessor rather than the public
// `lookup`, which would re-check both of them at every element.
#let _rebuild(node, transform, registry, depth, max-depth) = {
  if is-marker(node) { return (node: transform(node), found: true) }
  // An image is an opaque leaf: its equality is instance identity, so no
  // reconstruction of one can equal the original.
  if is-elem(node, image) { return (node: node, found: false) }

  if type(node) in (array, dictionary) {
    // Climbs on a nested container for the reason `_has-marker` does.
    let children = if type(node) == array { node } else { node.values() }
    let built = ()
    let found = false
    for child in children {
      let reached = _container-depth(child, depth)
      if reached > max-depth { _depth-error(max-depth) }
      let result = _rebuild(child, transform, registry, reached, max-depth)
      built.push(result.node)
      found = found or result.found
    }
    if not found { return (node: node, found: false) }
    if type(node) == array { return (node: built, found: true) }
    let rebuilt = (:)
    for (index, key) in node.keys().enumerate() {
      rebuilt.insert(key, built.at(index))
    }
    return (node: rebuilt, found: true)
  }

  if type(node) != content { return (node: node, found: false) }
  if depth > max-depth { _depth-error(max-depth) }

  let built = (:)
  let found = false
  for (name, value) in node.fields() {
    let result = _rebuild(value, transform, registry, depth + 1, max-depth)
    built.insert(name, result.node)
    found = found or result.found
  }
  if not found { return (node: node, found: false) }

  let fn = node.func()
  let entry = _get(registry, fn, "rebuild")
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

  let fields = _strip-synthesised(fn, built)
  let element-label = fields.remove("label", default: none)

  // An optional positional parameter that was never set is absent from
  // fields(), and Typst binds the positional arguments that remain by type,
  // so `align[x]` rebuilds from its body alone.
  let positional = entry.positional.filter(name => name in fields)

  let named = (:)
  for (name, value) in fields {
    if not positional.contains(name) { named.insert(name, value) }
  }
  let values = positional.map(name => fields.at(name))

  // A variadic container holds its children in one field that has itself to
  // be spread into separate arguments. A sequence takes its children whole.
  let arguments = if (entry.spread and values.len() == 1) {
    values.first()
  } else {
    values
  }

  let rebuilt = fn(..named, ..arguments)
  (
    node: if element-label == none { rebuilt } else { [#rebuilt#element-label] },
    found: true,
  )
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
///
/// `max-depth` bounds the authored nesting levels the rebuild descends. It is
/// the stricter of the two walks, since every level costs a detection call as
/// well as a reconstruction, so it is what sets the default. See `MAX-DEPTH`.
/// @category core
/// @returns content, or the value given when it holds no marker
#let rebuild(node, transform, registry: none, max-depth: MAX-DEPTH) = {
  if type(transform) != function {
    fail-type("rebuild", "transform", transform, "a function")
  }
  if (registry != none and type(registry) != dictionary) {
    fail-type("rebuild", "registry", registry, "a dictionary or none")
  }
  if type(max-depth) != int or max-depth < 1 {
    fail-type("rebuild", "max-depth", max-depth, "a positive integer")
  }
  // Resolved once here so the walk reads the registry through `_get` rather
  // than through `lookup`, which would re-run both checks above at every
  // element it reached.
  let resolved = if registry == none { builtin-registry() } else { registry }
  _rebuild(node, transform, resolved, 0, max-depth).node
}
