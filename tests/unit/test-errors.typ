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

errors tests passed.
