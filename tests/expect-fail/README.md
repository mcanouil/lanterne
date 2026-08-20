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

Covers every guard in `src/`: token name and value validation, theme construction and merging, the marker kinds, `register-container` and `lookup` argument validation and the spread arity rule, the registry shape check, the traversal depth bound including nesting made only of arrays or only of dictionaries, `has-marker` and `rebuild` argument validation, the unregistered element that carries a step marker, splitter argument types, slide record validation including its cross-field rules and its option vocabulary, the slide splitter's arguments and the placement rule for the option marker, the deck's own options and its document metadata vocabulary, and the error grammar's own hint guard.
`expand`'s own six guards are covered too: its `body`, `dim`, `steps` and `keep` argument validation, a pause the split cannot reach, and an unexpected marker reaching step resolution.
The heading refusal a stepped region delegates to and a `context-slide` callback that returns something other than content are covered alongside them, and so is the shape of each `keep` entry.
The counting the freezing arithmetic rests on is covered as well: `increments`'s `body`, and `collect`'s predicate and depth bound.
So are `rebuild`'s `match` and `keep-labels` arguments, along with the three labels suppression refuses rather than drops: one on an image, which cannot be rebuilt, one on a marker, and one under a container that is not registered.
The theme's two reserved keys carry their own guards: an unknown slot name and a non-function slot, on the override side and on the base side alike, and a `none` in a base, which clears a slot only where an override writes it.
The light and dark pair is covered through `deck`, which is what an author writes: a pair missing a half, a pair carrying a token beside its halves, a half that is not a dictionary, a bad token in the half this render does not select, an unknown `theme-mode`, and a whole pair handed to `theme-merge`, which merges one half at a time.

Add a case with the guard, in the same commit.
A guard with no case here is a guard that can be deleted without the build noticing.
