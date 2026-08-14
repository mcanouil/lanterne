# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- fix: `split-on` keeps the label of a group that opens with a `set` or `show` rule. Rebuilding the wrapper dropped it, so a reference to such a group failed with `label does not exist in the document`, and content equality ignores labels so no test comparing segments could notice. Where a boundary cuts through the group, the label goes on the last segment, matching the rule for steps.

- feat: `lib.typ` exports the package surface that exists: `theme-tokens` and `theme-merge`. The package is importable for the first time, though it does not render a deck until the next milestone.
- feat: add `theme-tokens` and `theme-merge`, the two ways a theme is built. Both validate every key they touch, so an unknown token name or a value of the wrong type fails where it is written rather than where it is read, and the message names the function you called.
- feat: add the theme token vocabulary, with a default and a validation rule for every canonical name, and a reserved `extra` namespace for tokens of your own. An unrecognised token name is an error rather than a silent no-op, because a theme that ignores a typo rots quietly.
- fix: an error's hint always ends the message as a sentence. A hint written without a closing mark produced a message that trailed off, which the grammar promised could not happen; one that already ends in `.`, `!` or `?` keeps the mark its author chose, and one that is blank is treated as absent rather than yielding a stop on its own.
- feat: add error grammar module.
- feat: add step markers.
- feat: add container registry.
- feat: add generic marker detection.
- feat: add content reconstruction.
- feat: add sequence splitter.
- test: cover the wrappers Quarto's Typst writer emits.
- fix: `split-on` finds the boundaries that follow a `set` or `show` rule instead of returning the whole body as a single segment, and keeps those rules in force over every segment. A deck sets things after `#show: deck.with(...)`, which wraps the body the deck receives, so this affected every deck rather than an unusual one.
- refactor: drop `check` from the error grammar. Nothing called it, and every validation in the package is written as `if <invalid> { fail-... }` instead.
- fix: `split-on` applies a rule in force over the whole body once per segment rather than once per stretch of children between the wrappers nested under it. A body carrying a second `set` or `show` rule after some content, or a `#[#set ...]` group, opened a page group per stretch and rendered on as many pages. An empty segment now carries the rules in force over it too, so a leading `#pause` no longer yields a step without the page setup its siblings have.
- fix: deeply nested content fails with a message naming the cause instead of Typst's bare recursion error. The depth bound now counts authored nesting levels rather than internal field hops, it holds across the whole walk rather than restarting inside each rebuild, and it sits at 30 rather than 24, roughly twice the depth generated content reaches. `has-marker` and `rebuild` take `max-depth` to raise it further. The old bound rejected content Quarto routinely generates while passing content that then died inside Typst.
