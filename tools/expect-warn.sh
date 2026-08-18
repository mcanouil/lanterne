#!/usr/bin/env bash
# Compiles every case under tests/expect-warn/ and asserts that each one
# compiles and warns, with the warning recorded in its own "// EXPECT:" lines.
#
# tools/check.sh fails a compile that writes anything to stderr, because a
# warning is how Typst reports content that did not converge. That rule is a
# comparison against an empty string, so nothing in tests/unit/ or in
# tests/expect-fail/ exercises it: the first suite compiles silently and the
# second never exits zero. Without a case here the rule can be reverted and
# every suite still passes, which is the failure the expect-fail cases exist to
# prevent for a panic.

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

# Collapse every run of whitespace to one space, for the reason
# tools/expect-fail.sh does it: Typst wraps a long message across lines and
# indents the continuation.
normalise() {
  tr '\n' ' ' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'
}

failures=0
passed=0
total=0

for f in tests/expect-warn/*.typ; do
  total=$((total + 1))
  expected="$(sed -n 's|^// EXPECT: ||p' "${f}" | normalise)"

  if [[ -z "${expected}" ]]; then
    printf '  FAIL  %s  no "// EXPECT:" line, so the case asserts nothing\n' "${f}"
    failures=$((failures + 1))
    continue
  fi

  # Only stderr is captured, as in tools/check.sh, so the assertion is about
  # the diagnostic and not about anything printed on success.
  if ! out=$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1 1>/dev/null); then
    printf '  FAIL  %s  failed to compile, but was expected to compile and warn\n' "${f}"
    printf '%s\n' "${out}"
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

printf '%-13s %d/%d\n' "expect-warn:" "${passed}" "${total}"

# An empty directory would report 0/0 and pass, which disarms the only check
# that exercises the stderr rule in tools/check.sh and in the CI action.
if [[ ${total} -eq 0 ]]; then
  printf '\nno expect-warn cases found, so nothing exercises the warning rule.\n' >&2
  exit 1
fi

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d case(s) did not warn as recorded.\n' "${failures}" >&2
  exit 1
fi
