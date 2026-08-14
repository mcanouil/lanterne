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
