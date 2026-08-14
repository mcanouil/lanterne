///! Unified error reporting for src/.
///!
///! Typst cannot catch a panic, so the message builders are pure functions
///! returning strings (tests/unit/test-errors.typ asserts their wording) and
///! the `fail-*` / `check` wrappers raise them.
///!
///! Grammar: "<scope>: <problem>; got <repr(value)>. <hint>"
///!
///! Never inline a panic string elsewhere in src/; route every validation here.

/// Render an array of values as a comma-joined list of `repr` forms.
/// @category utils
/// @returns str
#let quote-each(values) = {
  assert(values.len() > 0, message: "errors: quote-each needs a non-empty array.")
  values.map(repr).join(", ")
}

#let _with-hint(text, hint) = if hint == none { text } else { text + " " + hint }

/// "<scope>: <problem>." plus optional hint.
/// @category utils
/// @returns str
#let error-text(scope, problem, hint: none) = {
  _with-hint(scope + ": " + problem + ".", hint)
}

/// "<scope>: <name> must be one of "a", "b"; got <repr(value)>."
/// @category utils
/// @returns str
#let enum-text(scope, name, value, valid, hint: none) = {
  error-text(
    scope,
    name + " must be one of " + quote-each(valid) + "; got " + repr(value),
    hint: hint,
  )
}

/// "<scope>: <name> must be <expected>; got <repr(value)>."
/// @category utils
/// @returns str
#let type-text(scope, name, value, expected, hint: none) = {
  error-text(scope, name + " must be " + expected + "; got " + repr(value), hint: hint)
}

/// Panic with a grammar-conformant message.
/// @category utils
#let fail(scope, problem, hint: none) = panic(error-text(scope, problem, hint: hint))

/// Panic because a value is outside an enumerated set.
/// @category utils
#let fail-enum(scope, name, value, valid, hint: none) = {
  panic(enum-text(scope, name, value, valid, hint: hint))
}

/// Panic because a value has the wrong type or shape.
/// @category utils
#let fail-type(scope, name, value, expected, hint: none) = {
  panic(type-text(scope, name, value, expected, hint: hint))
}

/// Assert with a grammar-conformant message, built only when `cond` fails.
/// @category utils
#let check(cond, scope, problem, hint: none) = {
  if not cond { fail(scope, problem, hint: hint) }
}
