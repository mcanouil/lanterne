# Contributing to Lanterne

Thanks for your interest in helping improve Lanterne.
This document explains where to file what, what to include in a bug report, and the basics of working on the source.

> [!IMPORTANT]
> Pull requests are not accepted for now.
> The internals shift between releases, and every review costs time taken from the work that moves the library forward.
> Bug reports and ideas are welcome, and the development setup below is documented for the point at which pull requests reopen.

## Where to file what

Pick the right channel before opening anything:

- **Bug report.**
  Use [Issues → Bug report](https://github.com/mcanouil/lanterne/issues/new?template=bug.yml) only for confirmed defects with a reproducible example.
- **Feature request or idea.**
  Open a thread in [Discussions → Ideas](https://github.com/mcanouil/lanterne/discussions/new?category=ideas).
  I redirect feature requests opened as issues.
- **Question or help.**
  Open a thread in [Discussions → Q&A](https://github.com/mcanouil/lanterne/discussions/new?category=q-a).
- **Existing thread.**
  Browse [Discussions](https://github.com/mcanouil/lanterne/discussions) before you create a new one.
  If a relevant thread exists, comment on it.

## Reporting a bug

Before submitting a bug, confirm all of the following:

1. You have searched the [issue tracker](https://github.com/mcanouil/lanterne/issues?q=is%3Aissue) and could not find a similar report.
2. You have updated to the latest released version of Lanterne and reproduced the bug on that version.
3. You are reporting a bug, not requesting a feature or asking a question.

Lanterne is not published to Typst Universe yet, so until the first release the only way to reproduce against it is a local checkout.

Every bug report must include:

- The Lanterne version or commit, and the Typst compiler version (`typst --version`).
- A minimal reproducible Typst document.
  Once the package is published this means importing via `#import "@preview/lanterne:<version>": *`; before then, import the local `lib.typ` by path.
- Numbered steps to reproduce.
- The expected behaviour and the actual behaviour, with any error output pasted verbatim inside a fenced code block.

## Accessibility

Keep contributed content accessible:

- Add descriptive alt text to every image, screenshot, or diagram you attach (`![alt text describing the image](url)`).
- Do not rely on colour alone to convey meaning in screenshots, examples, or slide output.
- Quote error output as text inside fenced code blocks rather than pasting it as an image.

## Development setup

The package metadata, compiler version, and excluded paths are defined in [`typst.toml`](typst.toml).
The library entry point is [`lib.typ`](lib.typ).
Source modules live under [`src/`](src/).
Tests live under [`tests/unit/`](tests/unit).
Helper scripts live under [`tools/`](tools), in particular [`tools/check.sh`](tools/check.sh) for local checks.
Short identifiers used across the source tree are catalogued in [`GLOSSARY.md`](GLOSSARY.md).
Consult that glossary before you introduce new short identifiers.

Lanterne has no runtime dependencies, and it must keep none.
No `@preview` import may appear anywhere under [`src/`](src/).

## Commit conventions

Commits follow [Conventional Commits](https://www.conventionalcommits.org).
Subject line only, no body or footer, ideally under 50 characters.

Record user-facing changes under `## Unreleased` in [`CHANGELOG.md`](CHANGELOG.md).
Purely internal commits (`ci`, `test`, internal `refactor`) are not recorded there.

Breaking changes use the `!` marker (for example `feat!:`) and additionally get their own `### Breaking changes` sub-section at the top of the current release in the changelog.

## Language

British English spelling throughout code, comments, and documentation.
Avoid em dashes and en dashes; restructure the sentence instead.
Write one sentence per line in markdown.
End every list item with a punctuation mark.
