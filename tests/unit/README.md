# Unit tests

Pure-function tests compiled via `typst compile` with `assert.eq` checks.

Covers: error message grammar, step markers, content traversal, content reconstruction, container registry, sequence splitting, the token vocabulary, theme construction and merging, the public facade, the wrappers Quarto's Typst writer emits.

These files assert the accepting paths only.
Typst cannot catch a panic, so every rejection is compiled as its own file under [`../expect-fail`](../expect-fail).
