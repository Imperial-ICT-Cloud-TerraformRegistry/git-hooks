#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# Dual-purpose script:
#
#   Standalone mode  (run directly, e.g. ./add-readme.sh or via a git alias):
#     - Ensures pre-commit is installed (installs via pip if missing).
#     - Runs `pre-commit run --all-files` in a retry loop (up to MAX_ATTEMPTS)
#       until all hooks pass.  This handles the common case where terraform_docs
#       modifies README.md on the first pass, leaving it unstaged and causing a
#       second run to be required before committing.
#
#   pre-commit framework mode  (called by pre-commit with PRE_COMMIT=1 set):
#     - Checks that README.md exists and stages it.
# ─────────────────────────────────────────────────────────────────────────────

if [ -z "${PRE_COMMIT}" ]; then
    # ── Standalone / retry-wrapper mode ──────────────────────────────────────

    # Ensure pre-commit is installed
    if ! command -v pre-commit &>/dev/null; then
        echo "pre-commit not found. Installing via pip..."
        pip install pre-commit || {
            echo "ERROR: Failed to install pre-commit. Please install it manually."
            exit 1
        }
        echo "pre-commit installed successfully."
    fi

    # Ensure pre-commit hooks are installed in the current repo
    echo "Running pre-commit install in $(pwd)..."
    pre-commit install || {
        echo "ERROR: Failed to run pre-commit install. Make sure you are inside a git repository."
        exit 1
    }

    MAX_ATTEMPTS=3
    EXIT_CODE=1

    # Stage everything before the first run so hooks see a clean starting state.
    # Hooks like terraform_docs modify files and leave them unstaged; subsequent
    # runs also re-stage after each failed attempt for the same reason.
    echo "Staging all changes before first run..."
    git add -A

    for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
        echo ""
        echo "──────────────────────────────────────────────────────"
        echo " pre-commit run --all-files  (attempt ${attempt}/${MAX_ATTEMPTS})"
        echo "──────────────────────────────────────────────────────"
        pre-commit run --all-files
        EXIT_CODE=$?

        if [ "${EXIT_CODE}" -eq 0 ]; then
            echo ""
            echo "All pre-commit hooks passed on attempt ${attempt}."
            # Stage any final modifications made by hooks on this passing run.
            git add -A
            break
        fi

        if [ "${attempt}" -lt "${MAX_ATTEMPTS}" ]; then
            echo ""
            echo "Some hooks modified files – re-staging and retrying..."
            git add -A
        fi
    done

    if [ "${EXIT_CODE}" -ne 0 ]; then
        echo ""
        echo "ERROR: pre-commit hooks still failing after ${MAX_ATTEMPTS} attempts."
        exit 1
    fi

    exit 0
fi

# ── pre-commit framework hook mode ───────────────────────────────────────────
FILE=README.md
if test -f "$FILE"; then
    git add README.md
    exit 0
else
    echo "$FILE does not exist. Add the README.md file to your repo before committing."
    exit 1
fi