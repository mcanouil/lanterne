# Lanterne

Create themable presentation slides with **control over layout and structural elements** for Typst.

_Lanterne_ is French for "lantern", after the magic lantern, the ancestor of the slide projector.
The library turns an ordinary Typst document into a deck, driving both slide breaks and overlay steps from a single content traversal.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/mcanouil/lanterne)

> [!WARNING]
> _Lanterne_ is in active development.
> The public API is not yet stable, and only part of it exists.
> It is not published to Typst Universe, so `#import "@preview/lanterne:0.1.0": *` does not resolve; use it from a clone.
> Overlay steps, layouts and the structural element catalogue are not implemented, so `#pause` does nothing and a slide is its title and its body.

## Documentation

The documentation is at **[m.canouil.dev/lanterne](https://m.canouil.dev/lanterne)**: every export with its arguments and defaults, worked examples, and the changelog.

The smallest deck that builds today is [`examples/hello-deck.typ`](examples/hello-deck.typ).

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
