errors-hint-not-string.typ
// The hint guard catches a programming error in src/, not a user error, so it
// is an assert rather than the grammar.
// EXPECT: errors: hint must be a string or none; got 1.
#import "../../src/utils/errors.typ": error-text
#let _ = error-text("step", "range is empty", hint: 1)
