#!/bin/bash
# PostToolUse hook (Write|Edit): scoped SPM package tests on risk-area files.
#
# test-plan.md §5 quality gate "swift test pakietów" wired as a per-edit layer
# (M3L3): when the agent edits a file inside SharedModels/ or AppDatabase/,
# run that package's test suite. Exit 2 + stderr feeds the failure back into
# the agent's context so it can self-correct in the next iteration.
#
# Fast by design: only the touched package builds (incremental, a few seconds
# warm). App-target files are ignored — xcodebuild is too slow for a per-edit
# hook, so that layer stays at pre-commit/CI (lesson rule: slow checks move up).

set -u

FILE=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[ -n "$FILE" ] || exit 0

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "$FILE" in
  *"/SharedModels/"*) PACKAGE="SharedModels" ;;
  *"/AppDatabase/"*)  PACKAGE="AppDatabase" ;;
  *) exit 0 ;;
esac

# swift test needs the full Xcode toolchain (xcode-select points at CLT).
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

OUTPUT=$(cd "$REPO_ROOT" && swift test --package-path "$PACKAGE" 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ]; then
  # Blocking feedback: the tail carries the compiler error or failing
  # assertion; 10k-char additionalContext limit means we trim hard.
  {
    echo "[hook] swift test --package-path $PACKAGE FAILED after editing $FILE"
    echo "$OUTPUT" | tail -30
  } >&2
  exit 2
fi

exit 0
