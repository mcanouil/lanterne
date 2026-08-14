# Expect-fail cases

Every file here is compiled by `tools/expect-fail.sh` and asserted to **fail**, with the message it produces matched against the `// EXPECT:` lines it carries.

Typst cannot catch a panic, so a validation guard cannot be exercised from inside a unit test: the compile that would prove the guard fires is the same compile that reports the test's result.
Recording the message in a comment documents it and tests nothing, and a guard deleted from `src/` leaves every unit test passing.
These cases invert the harness, so the message a user reads is the message the build checks.

## Adding a case

One rejection per file.
Write the call that must fail, and record the message above it:

```typst
// EXPECT: theme-tokens: bg must be a colour; got "red".
#import "../../src/theme/tokens.typ": check-token
#check-token("bg", "red", "theme-tokens")
```

Several `// EXPECT:` lines are joined with a space, so a long message wraps like any other comment.
The match is a substring test after whitespace is collapsed on both sides, because Typst wraps and indents a long message itself.

A file that compiles, or fails with a different message, or carries no `// EXPECT:` line at all, fails the suite.

Covers: token name and value validation, theme construction and merging, the traversal depth bound, the unregistered element that carries a step marker, splitter argument types, and the error grammar's own hint guard.
