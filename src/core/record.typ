///! The slide record: the one dictionary a slide is described by.
///!
///! Three producers build one: the splitter, from a heading and the content
///! under it; the explicit `slide(...)` form, from its arguments; and the
///! machine surface, from a dictionary a filter emitted. Validating in one
///! place is what lets the renderer read a record without re-checking it, and
///! is the same arrangement `theme-tokens` has for a token dictionary.
///!
///! Two shapes rather than three. A slide with no heading is a content slide
///! whose title is `none`, so the implicit lead-in slide, the one an explicit
///! `#pagebreak()` opens and an ordinary titled slide differ in their fields
///! rather than in their kind.
///!
///! There is no `layout` key. Layouts arrive at M7 with the code that resolves
///! them, and a key nothing reads is a key whose meaning no reader can check.
///! The option vocabulary below grows the same way.

#import "../utils/errors.typ": fail, fail-enum, fail-type

#let _KINDS = ("section", "content")

// Name, default and rule together, as src/theme/tokens.typ writes its token
// spec, so a default cannot drift away from the rule that governs it.
// `expected` completes "<name> must be ...".
//
// One entry today: `smaller` is the option page emission reads, and is the one
// the specification's own machine-surface example carries. `steps` arrives with
// the step engine, `appendix` with the correctness rules and `layout` with the
// layout system, each alongside the code that reads it.
#let _ATTRS = (
  smaller: (default: false, expected: "a boolean", ok: v => type(v) == bool),
)

// `label` names both a type and, below, a parameter. A helper written here
// reads the type, since the parameter shadows the name only inside the function
// that declares it.
#let _is-label(value) = type(value) == label

/// The slide options, every key at its default.
/// @category core
/// @returns dictionary
#let default-attrs() = {
  let attrs = (:)
  for (name, spec) in _ATTRS { attrs.insert(name, spec.default) }
  attrs
}

/// Panic unless `attrs` is a dictionary of known slide options.
///
/// `scope` names the caller, because options are only ever validated on behalf
/// of one and the author needs to know which call rejected their value.
/// @category core
#let check-attrs(attrs, scope) = {
  if type(attrs) != dictionary {
    fail-type(scope, "attrs", attrs, "a dictionary of slide options")
  }
  for (name, value) in attrs {
    let spec = _ATTRS.at(name, default: none)
    if spec == none {
      fail-enum(scope, "slide option", name, _ATTRS.keys())
    }
    if not (spec.ok)(value) {
      fail-type(scope, name, value, spec.expected)
    }
  }
}

/// Build a validated slide record.
///
/// `title`, `level` and `label` describe the heading the slide was opened by,
/// for whatever reads a record. They do not replace it: the heading stays in
/// `body`, where the style wrappers it was written under still govern it, so a
/// renderer places the body and reads these to know what the slide is called.
///
/// `title` and `level` stand or fall together: a title with no level describes a
/// heading at no level, and a level with no title describes a heading that is
/// not there.
///
/// `label` is carried because specification 4.7 relies on a labelled heading
/// creating a named destination, and content equality ignores labels, so a
/// dropped one is invisible to every equality assertion in the suite.
///
/// `attrs` comes back complete, every option it did not name sitting at its
/// default, so a reader never repeats a default that could then drift.
/// @category core
/// @returns dictionary
#let slide-record(
  body,
  kind: "content",
  title: none,
  level: none,
  label: none,
  attrs: (:),
) = {
  let scope = "slide-record"
  if kind not in _KINDS {
    fail-enum(scope, "kind", kind, _KINDS)
  }
  if type(body) != content {
    fail-type(scope, "body", body, "content")
  }
  if title != none and type(title) != content {
    fail-type(scope, "title", title, "content or none")
  }
  if level != none and (type(level) != int or level < 1) {
    fail-type(scope, "level", level, "a positive integer or none")
  }
  if label != none and not _is-label(label) {
    fail-type(scope, "label", label, "a label or none")
  }
  if title != none and level == none {
    fail(
      scope,
      "a title needs the level of the heading it came from; got " + repr(title),
      hint: "Pass level alongside title.",
    )
  }
  if level != none and title == none {
    fail(
      scope,
      "a level describes a heading, and this slide has no title; got " + repr(level),
      hint: "Pass title alongside level, or neither.",
    )
  }
  // A section slide is a divider, and a divider with nothing on it is a slide
  // the author did not ask for.
  if kind == "section" and title == none {
    fail(
      scope,
      "a section slide must have a title",
      hint: "Pass title, or build a content slide instead.",
    )
  }
  check-attrs(attrs, scope)

  let options = default-attrs()
  for (name, value) in attrs { options.insert(name, value) }

  (
    kind: kind,
    title: title,
    level: level,
    label: label,
    attrs: options,
    body: body,
  )
}
