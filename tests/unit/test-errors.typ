// Error message grammar: "<scope>: <problem>; got <repr(value)>. <hint>"

#import "../../src/utils/errors.typ": (
  enum-text, error-text, quote-each, type-text,
)

#assert.eq(quote-each(("a", "b")), "\"a\", \"b\"")

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
  type-text("step", "range", 0, "a positive integer"),
  "step: range must be a positive integer; got 0.",
)

errors tests passed.
