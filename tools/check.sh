#!/usr/bin/env bash
# Compiles every Typst example and unit test from the project root.
# Mirrors the .github/actions/typst-compile composite action so local runs
# match CI exactly. Exits non-zero on the first failure across all targets.
#
# Flags:
#   --snapshot       Also run the visual snapshot harness in --check mode.
#   --snapshot=ARGS  Pass ARGS through to tools/snapshot/run.lua, for example
#                    `--snapshot=--only=hello-deck`.
#
# The snapshot suite is opt-in here and always on in CI. It needs Lua and
# ImageMagick, which the other three suites do not, and a contributor without
# either should still be able to run the checks that gate the code.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/lanterne-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

snapshot_mode=""
snapshot_args=""
for arg in "$@"; do
  case "${arg}" in
  --snapshot) snapshot_mode="check" ;;
  --snapshot=*)
    snapshot_mode="check"
    snapshot_args="${arg#--snapshot=}"
    ;;
  *)
    printf 'unknown arg: %s\n' "${arg}" >&2
    exit 2
    ;;
  esac
done

failures=0
total=0

compile_glob() {
  local label="$1"
  local glob="$2"
  local label_passed=0
  local label_total=0

  local out
  local reason

  for f in ${glob}; do
    label_total=$((label_total + 1))
    total=$((total + 1))
    reason=""
    # Only stderr is captured, and stdout is dropped, so that whatever the
    # compiler prints on a successful run cannot be read as a diagnostic.
    if out=$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1 1>/dev/null); then
      # A compile that exits zero and warns fails here. A warning is how Typst
      # reports content that did not converge, and a deck that did not converge
      # renders wrong numbers rather than failing to render, which is the one
      # outcome this package refuses.
      if [[ -n "${out}" ]]; then
        reason="reported a warning"
      fi
    else
      reason="failed to compile"
    fi

    if [[ -z "${reason}" ]]; then
      label_passed=$((label_passed + 1))
    else
      failures=$((failures + 1))
      printf '  FAIL  %s  %s  %s\n' "${label}" "${f}" "${reason}"
      if [[ -n "${out}" ]]; then
        printf '%s\n' "${out}"
      fi
    fi
  done

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

compile_glob "unit" "tests/unit/*.typ"
compile_glob "examples" "examples/*.typ"

# The cases that must fail, then the cases that must warn. Both run even when a
# compile above failed, so one run reports everything rather than hiding a later
# suite behind an earlier one.
expect_fail_status=0
"${REPO_ROOT}/tools/expect-fail.sh" || expect_fail_status=$?

expect_warn_status=0
"${REPO_ROOT}/tools/expect-warn.sh" || expect_warn_status=$?

# The visual goldens. Opt-in locally, always on in CI, and counted as a failure
# rather than exiting here, so one run reports every suite.
snapshot_status=0
if [[ -n "${snapshot_mode}" ]]; then
  printf '\nsnapshots:\n'
  # shellcheck disable=SC2086  # snapshot_args is intentionally word-split
  lua "${REPO_ROOT}/tools/snapshot/run.lua" --check ${snapshot_args} || snapshot_status=$?
fi

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

if [[ ${expect_fail_status} -ne 0 ]]; then
  exit "${expect_fail_status}"
fi

if [[ ${expect_warn_status} -ne 0 ]]; then
  exit "${expect_warn_status}"
fi

if [[ ${snapshot_status} -ne 0 ]]; then
  exit "${snapshot_status}"
fi

printf '\n%d compile(s) ok.\n' "${total}"
