# Visual golden tests

A structural assertion cannot see what a slide looks like.
A theme or a layout can validate every argument it is given, pass every test in `tests/unit/`, and still put the title in the wrong place.
That is what these goldens are for.

## Layout

A golden is one page of one deck, as a PNG under `golden/`:

```text
tests/visual/golden/examples/hello-deck-1.png
tests/visual/golden/examples/hello-deck-2.png
```

The name is the deck's file name and the page number, unpadded.
A deck of ten pages therefore keeps the names its first nine pages already had.

Every `examples/*.typ` deck is a source, and nothing else is yet.
The goldens the specification asks for per preset theme, per layout and per element arrive with the milestones that add those things, in the commit that adds them.

## Running

```sh
lua tools/snapshot/run.lua --check
```

The harness needs ImageMagick's `compare` and refuses to run without it.
It compiles each deck at 144 ppi with `--ignore-system-fonts`, so only the fonts Typst embeds are used and the rendering does not depend on what is installed.
Comparison allows a 2% fuzz, which absorbs the sub-pixel rounding that differs between arm64 and x86_64, and no stray pixels at all.

Four things fail a run:

- A deck that does not compile.
- A page with no golden behind it.
- A golden with no page behind it, which is how a lost or renumbered page is caught.
- A page that differs from its golden by more than the tolerance.

Build artefacts land under `build/snapshot/`, which is ignored by Git.
A failed comparison writes a difference image beside them.

## Minting and refreshing

Goldens are minted by CI and nowhere else, and `--update` refuses to run locally.

A Typst release older or newer than the pinned `compiler` renders the same source differently, so a golden written on a contributor's machine passes there and fails everywhere else.
Dispatch the `Refresh visual snapshots` workflow on the branch instead:

```sh
gh workflow run snapshot-refresh.yml --ref <branch> -f direct=true
```

`direct` commits the goldens straight to the dispatched branch.
Without it the workflow opens a pull request against that branch and sets auto-merge.

That is also how a deck first gets its goldens.
Add the deck, open the pull request as a draft so the checks stay idle, dispatch the workflow, and mark the pull request ready once the goldens are on the branch.

GitHub resolves `workflow_dispatch` against the default branch, so this workflow can only be dispatched once it is on `main`.
That is why it lives here, with the harness, rather than with the goldens it mints: putting it in the same pull request as the gate would leave that pull request unable to produce what it needs to pass.
