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
Tests live under [`tests/unit/`](tests/unit), which assert the accepting paths, [`tests/expect-fail/`](tests/expect-fail), which compile the rejections, and [`tests/expect-warn/`](tests/expect-warn), which compile the documents that must warn.
Typst cannot catch a panic, so a validation guard cannot be exercised from inside a unit test; add a case under [`tests/expect-fail/`](tests/expect-fail) whenever you add one, and see that directory's README for the format.
A compile that writes anything to stderr is a failure, even when it exits zero.
A warning is how Typst reports content that did not converge, and such a document renders wrong numbers rather than failing to render, which is the one outcome this package refuses.
Helper scripts live under [`tools/`](tools), in particular [`tools/check.sh`](tools/check.sh) for local checks, which runs all three suites.
The visual goldens under [`tests/visual/`](tests/visual) are a fourth suite, run on its own with [`tools/snapshot/run.lua`](tools/snapshot/run.lua) because it needs Lua and ImageMagick that the others do not; see that directory's README.
Short identifiers used across the source tree are catalogued in [`GLOSSARY.md`](GLOSSARY.md).
Consult that glossary before you introduce new short identifiers.

Lanterne has no runtime dependencies, and it must keep none.
No `@preview` import may appear anywhere under [`src/`](src/).

## Documentation comments

The reference pages on the website are generated from the `///` blocks in [`src/`](src/) by [`tools/typstdoc/`](tools/typstdoc), run as a Quarto pre-render.
The source is the record, so a page is never edited: edit the comment.

Run the generator before you push a change to one:

```sh
lua tools/typstdoc/main.lua --check --strict
lua tools/typstdoc/test/run.lua
```

Without a `lua` on the path, `quarto pandoc lua` runs the same scripts through the interpreter Quarto embeds in its Pandoc.
That is what the site render uses, since the workflow that publishes it installs Quarto and nothing else.

Every definition carries a `///` block above it, and every block carries a `@category` tag.
The categories are `core`, `deck`, `step`, `emit`, `theme` and `utils`, and each one has a banner comment in [`lib.typ`](lib.typ) that has to agree with it.

A name re-exported from [`lib.typ`](lib.typ) is public, and a public name carries more:

- A `@stability` tag, per the table below.
- One `@param` line per parameter of its signature, which is what the parameter table on its page is built from.
- A `@returns` line, unless it is a value rather than a function.

Anything a module exports that `lib.typ` does not is internal on purpose.
It is parsed, so a malformed tag anywhere is still an error, but it takes none of the three and no page is written for it.

A code example goes in an `@examples-static` block rather than in the prose, where a fence would be folded into a paragraph.
`@examples` is the tag that compiles what it shows, and it needs a Typst engine the documentation site does not have yet.

The tag says which parts of the surface the 0.x contract actually threatens.
That contract permits a breaking change on a minor release, and without the tag a reader has to guess which names it applies to.

| Value | What it promises |
| --- | --- |
| `stable` | The signature and the meaning are settled. A change to either is a breaking change, recorded as one. |
| `experimental` | A milestone still to come will reshape this name. Expect the signature or the meaning to change on a minor release. |
| `deprecated` | Scheduled for removal, with the replacement named in the block. Unused today, since this package replaces rather than deprecates. |

Write the value out even when it is `stable`.
The reference generator treats an absent tag as `stable`, so silence and a promise would otherwise be the same thing.

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
