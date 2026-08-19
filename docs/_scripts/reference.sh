#!/usr/bin/env bash
#
# Documentation Reference Script
# Generates the reference pages under docs/reference/ from the /// comments in
# src/, and removes them again after the render.
#
# @license MIT License
# @copyright 2026 Mickaël Canouil
# @author Mickaël Canouil
#
# This is lanterne's own script rather than part of the scaffolded pair beside
# it. pre-render.sh and post-render.sh are vendored with the documentation
# website and kept byte-identical to the copy they came from, so re-scaffolding
# overwrites them without a diff to review; anything added to them would be lost
# without a word. _quarto.yml therefore names this script as a second pre-render
# and post-render entry.
#
# It is run twice per render, once in each phase, and the phase is given as its
# one argument.
#
# The generated tree is ignored by Git, as changelog.qmd and _variables.yml are.
# The source of truth is the /// comments; a page committed beside them would be
# a second copy to drift.
#
# --strict is deliberate. An unresolved @ref is a link the reader would follow
# to nothing, so it fails the render rather than publishing it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "${SCRIPT_DIR}")"
ROOT_DIR="$(dirname "${DOCS_DIR}")"

PHASE="${1:-pre}"

if [[ "${PHASE}" == "post" ]]; then
	rm -rf "${DOCS_DIR}/reference"
	printf '[post-render] Removed reference/\n'
	exit 0
fi

if ! command -v lua >/dev/null 2>&1; then
	printf '[pre-render] lua is not installed, and the reference is generated from the /// comments\n' >&2
	exit 1
fi

lua "${ROOT_DIR}/tools/typstdoc/main.lua" --root "${ROOT_DIR}" --strict

printf '[pre-render] src/**.typ -> reference/\n'
