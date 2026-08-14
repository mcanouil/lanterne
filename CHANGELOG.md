# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- feat: add error grammar module.
- feat: add step markers.
- feat: add container registry.
- feat: add generic marker detection.
- feat: add content reconstruction.
- feat: add sequence splitter.
- test: cover the wrappers Quarto's Typst writer emits.
- fix: `split-on` finds the boundaries that follow a `set` or `show` rule instead of returning the whole body as a single segment, and keeps those rules in force over every segment. A deck sets things after `#show: deck.with(...)`, which wraps the body the deck receives, so this affected every deck rather than an unusual one.
- fix: `split-on` applies a rule in force over the whole body once per segment rather than once per stretch of children between the wrappers nested under it. A body carrying a second `set` or `show` rule after some content, or a `#[#set ...]` group, opened a page group per stretch and rendered on as many pages. An empty segment now carries the rules in force over it too, so a leading `#pause` no longer yields a step without the page setup its siblings have.
- fix: deeply nested content fails with a message naming the cause instead of Typst's bare recursion error. The depth bound now counts authored nesting levels rather than internal field hops, it holds across the whole walk rather than restarting inside each rebuild, and it sits at 30 rather than 24, roughly twice the depth generated content reaches. `has-marker` and `rebuild` take `max-depth` to raise it further. The old bound rejected content Quarto routinely generates while passing content that then died inside Typst.
