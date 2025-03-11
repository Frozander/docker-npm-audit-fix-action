#!/bin/sh
set -e

# Get inputs from args
GITHUB_TOKEN="${1}"
GITHUB_USER="${2}"
GITHUB_EMAIL="${3}"
BRANCH="${4}"
DEFAULT_BRANCH="${5}"
COMMIT_TITLE="${6}"
LABELS="${7}"
ASSIGNEES="${8}"
NPM_ARGS="${9}"
PROJECT_PATH="${10}"
MONOREPO="${11}"
CONCURRENCY="${12}"

# Set default values if not provided
GITHUB_USER="${GITHUB_USER:-$GITHUB_ACTOR}"
GITHUB_EMAIL="${GITHUB_EMAIL:-"$GITHUB_ACTOR@users.noreply.github.com"}"
BRANCH="${BRANCH:-npm-audit-fix-action/fix}"
COMMIT_TITLE="${COMMIT_TITLE:-"build(deps): npm audit fix"}"
LABELS="${LABELS:-"dependencies, javascript, security"}"
PROJECT_PATH="${PROJECT_PATH:-.}"
MONOREPO="${MONOREPO:-false}"
CONCURRENCY="${CONCURRENCY:-2}"

echo "==== Environment ===="
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo "Current directory: $(pwd)"
echo "==== Arguments ===="
echo "Project path: $PROJECT_PATH"
echo "Monorepo: $MONOREPO"
echo "Concurrency: $CONCURRENCY"

# Ensure we're in the right directory
cd "$GITHUB_WORKSPACE/$PROJECT_PATH"

# Configure Git
git config --global user.name "$GITHUB_USER"
git config --global user.email "$GITHUB_EMAIL"

# Run the scripts
/action/scripts/audit_and_fix.sh "$NPM_ARGS" "$MONOREPO" "$CONCURRENCY"
/action/scripts/create_pr.sh "$GITHUB_TOKEN" "$BRANCH" "$DEFAULT_BRANCH" "$COMMIT_TITLE" "$LABELS" "$ASSIGNEES" 