#!/usr/bin/env bash
# Compiles every Typst example and unit test from the project root.
# Mirrors the .github/actions/typst-compile composite action so local runs
# match CI exactly. Exits non-zero on the first failure across all targets.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/lanterne-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

if [[ $# -gt 0 ]]; then
  printf 'unknown arg: %s\n' "$1" >&2
  exit 2
fi

failures=0
total=0

compile_glob() {
  local label="$1"
  local glob="$2"
  local label_passed=0
  local label_total=0

  local out

  for f in ${glob}; do
    label_total=$((label_total + 1))
    total=$((total + 1))
    # stderr is captured rather than discarded, because a compile that exits
    # zero and warns is a failure here. A warning is how Typst reports content
    # that did not converge, and a deck that did not converge renders wrong
    # numbers rather than failing to render, which is the one outcome this
    # package refuses.
    if out=$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1) &&
      [[ -z "${out}" ]]; then
      label_passed=$((label_passed + 1))
    else
      failures=$((failures + 1))
      printf '  FAIL  %s  %s\n' "${label}" "${f}"
      if [[ -n "${out}" ]]; then
        printf '%s\n' "${out}"
      fi
    fi
  done

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

compile_glob "unit" "tests/unit/*.typ"
compile_glob "examples" "examples/*.typ"

# The cases that must fail. Run even when a compile above failed, so one run
# reports everything rather than hiding the second suite behind the first.
expect_fail_status=0
"${REPO_ROOT}/tools/expect-fail.sh" || expect_fail_status=$?

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

if [[ ${expect_fail_status} -ne 0 ]]; then
  exit "${expect_fail_status}"
fi

printf '\n%d compile(s) ok.\n' "${total}"
