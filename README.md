# Lanterne

Create themable presentation slides with **control over layout and structural elements** for Typst.

_Lanterne_ is French for "lantern", after the magic lantern, the original slide projector.
The library renders decks from ordinary Typst documents, with one content traversal driving both slide breaks and overlay steps.

> [!WARNING]
> _Lanterne_ is in active development.
> Nothing in the public API is stable, and the package does not yet render slides.
> See [Status](#status) for what exists today.

## Design

A single content traversal drives the whole package.
Applied with a heading predicate it yields slides, applied with a marker predicate it yields overlay steps.

Two properties follow, and they are why this package exists alongside the established alternatives:

- **Detection is total.**
  A step marker nested inside any element is found, so it can never be silently dropped.
  Where an element cannot be rebuilt, compilation fails with the element name and the fix, rather than producing a wrong deck.
- **The element vocabulary is designed to be machine emitted.**
  A second, narrow surface takes plain dictionaries, strings and content only, so a document generator drives the package as easily as a human does.

## Status

Implemented:

- Package scaffolding and the local check harness.

Not yet implemented:

- Everything else: slides, steps, themes, layouts and every structural element.

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

## Citation

If you use _Lanterne_ in your work, cite it.
Citation metadata is provided in [`CITATION.cff`](CITATION.cff).
GitHub renders it via the "Cite this repository" widget on the repository sidebar.

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
