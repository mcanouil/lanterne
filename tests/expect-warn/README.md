# Expect-warn cases

Every file here is compiled by `tools/expect-warn.sh` and asserted to **compile and warn**, with the warning matched against the `// EXPECT:` lines it carries.

`tools/check.sh` fails any compile that writes to stderr, because a warning is how Typst reports content that did not converge, and such a document renders wrong numbers rather than failing to render.
That rule is a comparison against an empty string, so no other suite reaches it: `tests/unit/` compiles silently and `tests/expect-fail/` never exits zero.
Without a case here the rule can be reverted and every suite still passes, which is exactly what the expect-fail cases prevent for a panic.

## Adding a case

One warning per file, written against the public surface so it keeps warning as the package changes.
Record the warning above it, as an expect-fail case records its message:

```typst
// EXPECT: document did not converge within five attempts
#import "/lib.typ": *
```

The match is a substring test after whitespace is collapsed on both sides, the rule `tools/expect-fail.sh` already uses, because Typst wraps and indents a long message itself.

A file that fails to compile, or compiles with nothing on stderr, or carries no `// EXPECT:` line at all, fails the suite.
