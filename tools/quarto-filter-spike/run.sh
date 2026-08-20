#!/usr/bin/env bash
#
# Run the throwaway emit-surface spike: convert deck.qmd through filter.lua and
# compile the result against lanterne.
#
# Specification section 12.2 asks for this, to falsify the emission contract of
# section 3.2 while it is still cheap to change. It is deleted when the real
# extension begins, after M9.
#
# Pandoc is invoked directly rather than through `quarto render`, and that is a
# finding rather than a preference. Quarto compiles the `.typ` it produces with
# the Typst root set to the document's own directory, so the deck cannot reach a
# package that lives above it: neither `/lib.typ` nor `../../lib.typ` resolves,
# and Typst says so by name. The real extension does not meet this, because it
# vendors the package under `_extensions/<name>/typst/packages` and imports it
# as `@local/lanterne`. That vendoring requirement in specification section 11
# is therefore load-bearing rather than tidiness.
#
# The two steps here are the two halves of the real pipeline: Pandoc does the
# mapping, Typst does the compiling, and the root is set where the package is.
#
# `--shift-heading-level-by` is deliberately absent. Quarto passes -1 to its own
# Typst render, because the document title is the level 1 heading and the body
# starts at level 2. Under that shift a `##` slide heading reaches the deck as
# level 1, which is below the default slide level, so every slide renders as a
# section slide with its body centred. A filter-based extension has to either
# undo that shift or set `slide-level` to match it, and this is where that was
# found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/spike"

mkdir -p "${OUT_DIR}"

quarto pandoc "${SCRIPT_DIR}/deck.qmd" \
  --from markdown \
  --to typst \
  --standalone \
  --wrap none \
  --template "${SCRIPT_DIR}/template.typ" \
  --lua-filter "${SCRIPT_DIR}/filter.lua" \
  --output "${OUT_DIR}/deck.typ"

printf '[spike] deck.qmd -> %s\n' "${OUT_DIR}/deck.typ"

# --root is the repository, so `lib.typ` in the template resolves to the package
# under test rather than to nothing.
typst compile "${OUT_DIR}/deck.typ" --root "${ROOT_DIR}" "${OUT_DIR}/deck.pdf"

printf '[spike] compiled %s\n' "${OUT_DIR}/deck.pdf"
