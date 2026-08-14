///! Unified error reporting for src/.
///!
///! Typst cannot catch a panic, so the message builders are pure functions
///! returning strings (tests/unit/test-errors.typ asserts their wording) and
///! the `fail-*` wrappers raise them.
///!
///! Grammar: "<scope>: <problem>; got <repr(value)>. <hint>"
///!
///! A hint is a sentence and is finished as one here when the caller has not
///! written it that way, so the single trailing stop the grammar promises
///! holds whatever a call site passes.
///!
///! Never inline a panic string elsewhere in src/; route every validation here.

/// Render an array of values as a comma-joined list of `repr` forms.
/// @category utils
/// @returns str
#let repr-each(values) = {
  assert(values.len() > 0, message: "errors: repr-each needs a non-empty array.")
  values.map(repr).join(", ")
}

// The grammar promises one trailing stop. A hint is a sentence, so a hint that
// does not already end as one is finished here rather than at every call site,
// where a missing stop is invisible until a user reads the message.
#let _SENTENCE-ENDS = (".", "!", "?")

#let _with-hint(message, hint) = {
  if hint == none { return message }
  assert(
    type(hint) == str,
    message: "errors: hint must be a string or none; got " + repr(hint) + ".",
  )
  let finished = if _SENTENCE-ENDS.any(end => hint.ends-with(end)) { hint } else { hint + "." }
  message + " " + finished
}

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
