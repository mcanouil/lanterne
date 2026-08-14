// Error message grammar: "<scope>: <problem>; got <repr(value)>. <hint>"

#import "../../src/utils/errors.typ": (
  enum-text, error-text, repr-each, type-text,
)

#assert.eq(repr-each(("a", "b")), "\"a\", \"b\"")

#assert.eq(repr-each((1, 2)), "1, 2")

#assert.eq(repr-each((none, true)), "none, true")

#assert.eq(repr-each(("a\"b",)), "\"a\\\"b\"")

#assert.eq(error-text("step", "range must not be empty"), "step: range must not be empty.")

#assert.eq(
  error-text("step", "range must not be empty", hint: "Use \"2-\"."),
  "step: range must not be empty. Use \"2-\".",
)

#assert.eq(
  enum-text("step", "before", "gone", ("visible", "hidden", "dimmed", "removed")),
  "step: before must be one of \"visible\", \"hidden\", \"dimmed\", \"removed\"; got \"gone\".",
)

#assert.eq(
  enum-text("step", "before", "gone", ("visible", none)),
  "step: before must be one of \"visible\", none; got \"gone\".",
)

// An empty valid set is reported to the caller, not to whoever wrote the helper.
#assert.eq(
  enum-text("theme", "token", "bg", ()),
  "theme: token has no permitted values; got \"bg\".",
)

#assert.eq(
  type-text("step", "range", 0, "a positive integer"),
  "step: range must be a positive integer; got 0.",
)

// The grammar promises exactly one trailing stop, so a hint that is not
// already a sentence is finished rather than appended raw. Without this the
// promise held only where the caller happened to write one, and a missing
// stop is invisible until a user reads the message.
#assert.eq(
  error-text("theme-tokens", "bg must be a colour", hint: "Pass a colour value"),
  "theme-tokens: bg must be a colour. Pass a colour value.",
)

// A hint that already ends as a sentence is left exactly as written, whichever
// of the three marks ends it.
#assert.eq(
  error-text("step", "range is empty", hint: "Did you mean \"2-\"?"),
  "step: range is empty. Did you mean \"2-\"?",
)

#assert.eq(
  error-text("step", "range is empty", hint: "Never write this!"),
  "step: range is empty. Never write this!",
)

// Normalisation reaches the wrappers too, since neither builds its message
// itself.
#assert.eq(
  enum-text("theme", "token", "bgg", ("bg",), hint: "Try bg"),
  "theme: token must be one of \"bg\"; got \"bgg\". Try bg.",
)

#assert.eq(
  type-text("theme", "margin", 1, "a length", hint: "Write 2cm"),
  "theme: margin must be a length; got 1. Write 2cm.",
)

errors tests passed.
