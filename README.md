# Lanterne

Create themable presentation slides with **control over layout and structural elements** for Typst.

_Lanterne_ is French for "lantern", after the magic lantern, the ancestor of the slide projector.
The library turns an ordinary Typst document into a deck, driving both slide breaks and overlay steps from a single content traversal.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/mcanouil/lanterne)

> [!WARNING]
> _Lanterne_ is in active development.
> The public API is not yet stable, and only part of the surface below exists.
> It is not published to Typst Universe, so the import shown below does not resolve.
> The snippet shows the intended API, not what ships today.

## Status

Implemented, the traversal core the rest of the package is built on:

- Package scaffolding and the local check harness.
- The error message grammar every validation routes through.
- Step markers, the sentinels the traversal looks for.
- Marker detection, which reaches anything a Typst element exposes.
- Content reconstruction, driven by a registry of the elements that cannot be rebuilt by spreading their fields, and failing loudly rather than silently dropping a marker it cannot carry.
- The splitter that turns a body into segments, which yields slides when applied with a heading predicate and steps when applied with a marker predicate.
- The theme token vocabulary, with a default and a validation rule for every name, and a reserved `extra` namespace for tokens of your own.
- `theme-tokens` and `theme-merge`, the two ways a theme is built, both validating every key they touch.
- Slide splitting: a heading opens a slide, a level below the slide level opens a section slide, `#pagebreak()` and `slide(...)` open one by hand, and `slide-options(...)` attaches per-slide options.
- Page emission: `deck` renders each slide as one page, dressed by the theme's geometry, fonts and colours.

Not yet implemented:

- Overlay steps, so `#pause` and the step functions do nothing yet.
- Layouts, chrome and the structural element catalogue, so a slide is its title and its body.

## Quick look

What builds today, which is [`examples/hello-deck.typ`](examples/hello-deck.typ):

```typst
#import "../lib.typ": *

#show: deck.with(
  theme: theme-tokens(bg: rgb("#fbfbfd"), fg: rgb("#1c1c22")),
  aspect-ratio: "16-9",
  slide-level: 2,
  info: (title: [Hello, lanterne], author: "Mickaël Canouil"),
)

= Getting started

== What a deck is

A level 2 heading opens a slide and becomes its title.

== Set smaller

#slide-options(smaller: true)

This slide asked to be set smaller.
```

What the package is aiming at:

```typst
#import "@preview/lanterne:0.1.0": *

#show: deck.with(
  theme: theme-default(),
  aspect-ratio: "16-9",
  slide-level: 2,
  info: (
    title: [A short talk],
    author: [Mickaël Canouil],
    date: datetime.today(),
  ),
)

= Results

== Two columns

#columns-block(widths: (1fr, 1fr))[
  Left hand side.
][
  Right hand side.
]

#pause

A point revealed on the second step.

#callout(variant: "note", title: "Aside")[
  Structural elements are labelled, so ordinary `show` rules restyle them.
]

#note[Speaker note, exported for pdfpc.]
```

## Dependencies

None at runtime.
See [`typst.toml`](typst.toml) for the authoritative Typst compiler version.

## Contributing

> [!NOTE]
> Lanterne is an unfunded spare-time project, and the API is still settling.
> Bug reports and ideas are welcome on the issue tracker.
>
> I do not accept pull requests for now.
> The internals shift between releases.
> Every review costs time that I must take from the work that moves the library forward.
> I am also especially careful in the current climate of unreviewed LLM-authored patches.
> Once the surface is stable I will revisit and open the door.
>
> Thanks in advance for your patience and your understanding.

Bug reports and ideas are welcome, and [`CONTRIBUTING.md`](CONTRIBUTING.md) explains where to file each and what to include.
It also covers development setup and commit conventions, for the point at which pull requests reopen.
Short identifiers used across the source tree (`ctx`, `fn`, `lo`, `hi`, …) are catalogued in [`GLOSSARY.md`](GLOSSARY.md).

## Citation

If you use _Lanterne_ in your work, cite it.
Citation metadata is provided in [`CITATION.cff`](CITATION.cff).
GitHub renders it via the "Cite this repository" widget on the repository sidebar.

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
