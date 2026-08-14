///! Unified error reporting for src/.
///!
///! Typst cannot catch a panic, so the message builders are pure functions
///! returning strings (tests/unit/test-errors.typ asserts their wording) and
///! the `fail-*` wrappers raise them.
///!
///! Grammar: "<scope>: <problem>; got <repr(value)>. <hint>"
///!
///! Never inline a panic string elsewhere in src/; route every validation here.

/// Render an array of values as a comma-joined list of `repr` forms.
/// @category utils
/// @returns str
#let repr-each(values) = {
  assert(values.len() > 0, message: "errors: repr-each needs a non-empty array.")
  values.map(repr).join(", ")
}

#let _with-hint(message, hint) = if hint == none { message } else { message + " " + hint }

/// "<scope>: <problem>." plus optional hint.
/// @category utils
/// @returns str
#let error-text(scope, problem, hint: none) = {
  assert(type(scope) == str, message: "errors: scope must be a string; got " + repr(scope) + ".")
  assert(
    type(problem) == str,
    message: "errors: problem must be a string; got " + repr(problem) + ".",
  )
  _with-hint(scope + ": " + problem + ".", hint)
}

/// "<scope>: <name> must be one of "a", 1, none; got <repr(value)>."
/// An empty `valid` reports that the parameter permits nothing.
/// @category utils
/// @returns str
#let enum-text(scope, name, value, valid, hint: none) = {
  let problem = if valid.len() == 0 {
    name + " has no permitted values; got " + repr(value)
  } else {
    name + " must be one of " + repr-each(valid) + "; got " + repr(value)
  }
  error-text(scope, problem, hint: hint)
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
