#!/usr/bin/env bash
# Compiles every case under tests/expect-fail/ and asserts that each one fails
# with the message recorded in its own "// EXPECT:" lines.
#
# Typst cannot catch a panic, so a validation guard cannot be exercised from
# inside a unit test: the compile that would prove the guard fires is the same
# compile that reports the test's result. Recording the message in a comment
# documents it but tests nothing, and a deleted guard leaves every unit test
# passing. These cases invert the harness instead, so the message a user reads
# is the message the build checks.

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

# Collapse every run of whitespace to one space. Typst wraps a long message
# across lines and indents the continuation, so an expectation written on one
# line would otherwise never match one the compiler chose to break.
normalise() {
  tr '\n' ' ' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'
}

failures=0
passed=0
total=0

for f in tests/expect-fail/*.typ; do
  total=$((total + 1))
  expected="$(sed -n 's|^// EXPECT: ||p' "${f}" | normalise)"

  if [[ -z "${expected}" ]]; then
    printf '  FAIL  %s  no "// EXPECT:" line, so the case asserts nothing\n' "${f}"
    failures=$((failures + 1))
    continue
  fi

  if out=$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1); then
    printf '  FAIL  %s  compiled, but was expected to fail\n' "${f}"
    failures=$((failures + 1))
    continue
  fi

  actual="$(printf '%s' "${out}" | normalise)"
  if [[ "${actual}" == *"${expected}"* ]]; then
    passed=$((passed + 1))
  else
    printf '  FAIL  %s\n' "${f}"
    printf '    expected: %s\n' "${expected}"
    printf '    actual:   %s\n' "${actual}"
    failures=$((failures + 1))
  fi
done

printf '%-13s %d/%d\n' "expect-fail:" "${passed}" "${total}"

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d case(s) did not fail as recorded.\n' "${failures}" >&2
  exit 1
fi
