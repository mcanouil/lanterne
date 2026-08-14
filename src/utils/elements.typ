///! Facts about Typst's content model that the traversal needs.
///!
///! Two of the element functions the package has to name have no public
///! binding, so they are obtained from a sample value. Both the registry and
///! the splitter need them, and a test that constructs one of these shapes
///! needs them too, so they live here rather than being re-derived per
///! module: the sample-value trick has to be re-verified after a Typst
///! upgrade, and one copy re-verified while another is missed is how a
///! silently wrong deck happens.
///!
///! Nothing here is part of the deck model. This module knows what a Typst
///! element is, not what a slide is.

/// The element function of a bare content sequence.
///
/// A sequence is what adjacent content becomes, so a body's children are
/// reached through it. It has no public binding, hence the sample value.
/// @category utils
#let SEQUENCE = [*a* b].func()

/// The element function of a `set` or `show` rule's wrapper.
///
/// A rule wraps everything it governs in one of these, with the wrapped
/// content in `child` and the rules in `styles`. It has no public binding,
/// hence the sample value. `docs/notes/roundtrip-findings.md` records the
/// verified positional order for reconstructing one.
/// @category utils
#let STYLED = text(size: 12pt)[x].func()

/// Whether `node` is content built by the element function `fn`.
///
/// `node.func()` is only defined on content, so the type test has to come
/// first. Written out at each call site this is a two-clause guard that reads
/// as plumbing rather than as the question being asked.
/// @category utils
/// @returns bool
#let is-elem(node, fn) = type(node) == content and node.func() == fn
