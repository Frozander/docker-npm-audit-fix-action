#!/bin/sh
set -e

NPM_ARGS="$1"

echo "==== Running npm audit fix ===="

# Get the initial audit report
echo "Getting initial audit report..."
npm_audit_output=$(npm audit --json 2>/dev/null || true)
echo "$npm_audit_output" > /tmp/audit-before.json

# Install dependencies if package-lock.json exists but node_modules doesn't
if [ -f "package-lock.json" ] && [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  if [ -z "$NPM_ARGS" ]; then
    npm ci
  else
    npm ci $NPM_ARGS
  fi
fi

# List packages before fix
echo "Listing packages before fix..."
npm list --json > /tmp/packages-before.json

# Run npm audit fix
echo "Running npm audit fix..."
if [ -z "$NPM_ARGS" ]; then
  npm audit fix || echo "Warning: npm audit fix exited with non-zero status"
else
  npm audit fix $NPM_ARGS || echo "Warning: npm audit fix exited with non-zero status"
fi

# Reinstall packages to ensure everything is consistent
echo "Reinstalling packages..."
if [ -z "$NPM_ARGS" ]; then
  npm ci
else
  npm ci $NPM_ARGS
fi

# List packages after fix
echo "Listing packages after fix..."
npm list --json > /tmp/packages-after.json

# Get the final audit report
echo "Getting final audit report..."
npm audit --json > /tmp/audit-after.json 2>/dev/null || true

# Check if files have been changed
if git diff --quiet; then
  echo "No changes detected after npm audit fix"
  exit 0
else
  echo "Changes detected after npm audit fix"
  # Display a summary of changes
  git diff --name-status
fi 