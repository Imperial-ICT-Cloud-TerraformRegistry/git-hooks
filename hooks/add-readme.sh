#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────────
# Dual-purpose script:
#
#   Installer / setup mode  (run directly once per repo):
#     - Ensures pre-commit CLI is installed (installs via pip if missing).
#     - Writes a retry-wrapper into .git/hooks/pre-commit so that every future
#       `git commit` automatically retries pre-commit run --all-files until all
#       hooks pass.  Handles the common case where terraform_docs modifies
#       README.md during the hook run, leaving it unstaged.
#
#   pre-commit framework mode  (called by pre-commit with PRE_COMMIT=1 set):
#     - Checks that README.md exists and stages it.
# ─────────────────────────────────────────────────────────────────────────────

if [ -z "${PRE_COMMIT}" ]; then
    # ── Installer mode ────────────────────────────────────────────────────────

    # Ensure pre-commit CLI is available
    if ! command -v pre-commit &>/dev/null; then
        echo "pre-commit not found. Installing via pip..."
        pip install pre-commit || {
            echo "ERROR: Failed to install pre-commit. Please install it manually."
            exit 1
        }
        echo "pre-commit installed successfully."
    fi

    # Locate the .git directory for the current repo
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || {
        echo "ERROR: Not inside a git repository."
        exit 1
    }

    HOOK_FILE="${GIT_DIR}/hooks/pre-commit"
    mkdir -p "${GIT_DIR}/hooks"

    # Write the retry-wrapper as the git pre-commit hook.
    # This replaces whatever pre-commit install would have written, giving us
    # full control over the retry loop.  The wrapper calls
    # `pre-commit run --all-files` directly (reading .pre-commit-config.yaml),
    # which sets PRE_COMMIT=1 for every hook child-process — so this script
    # itself will take the framework-hook path below rather than looping again.
    cat > "${HOOK_FILE}" << 'EOF'
#!/bin/bash
# Auto-retry pre-commit wrapper.
# Installed by add-readme.sh – do not edit manually.
# Re-run:  bash /path/to/git-hooks/hooks/add-readme.sh  to reinstall.

MAX_ATTEMPTS=5
EXIT_CODE=1

echo ""
echo "Staging all changes before running pre-commit checks..."
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
        # Stage any files modified by hooks on the passing run itself.
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
EOF

    chmod +x "${HOOK_FILE}"

    echo ""
    echo "✔  Retry-wrapper installed at: ${HOOK_FILE}"
    echo "   Every 'git commit' in this repo will now automatically retry"
    echo "   pre-commit run --all-files until all hooks pass."
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