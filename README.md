# Lanterne

Create themable presentation slides with **control over layout and structural elements** for Typst.

_Lanterne_ is French for "lantern", after the magic lantern, the ancestor of the slide projector.
The library turns an ordinary Typst document into a deck, driving both slide breaks and overlay steps from a single content traversal.

Documentation: <https://m.canouil.dev/lanterne>.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/mcanouil/lanterne)

> [!WARNING]
> _Lanterne_ is in active development.
> The public API is not yet stable, and the package does not render slides yet.
> The snippet below shows the intended API, not what ships today.

## Quick look

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

Contributions are welcome.
See [`CONTRIBUTING.md`](CONTRIBUTING.md) for bug reporting, development setup, and commit conventions.
Short identifiers used across the source tree (`ctx`, `fn`, `lo`, `hi`, …) are catalogued in [`GLOSSARY.md`](GLOSSARY.md).

## Citation

If you use _Lanterne_ in your work, cite it.
Citation metadata is provided in [`CITATION.cff`](CITATION.cff).
GitHub renders it via the "Cite this repository" widget on the repository sidebar.

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
