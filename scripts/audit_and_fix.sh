#!/bin/sh
set -e

NPM_ARGS="$1"
MONOREPO="$2"
CONCURRENCY="$3"

echo "==== Running npm audit fix ===="
echo "Monorepo mode: $MONOREPO"
echo "Concurrency: $CONCURRENCY"

# Create a temporary directory for audit reports
mkdir -p /tmp/npm-audit-reports

# Function to process a single package
process_package() {
  local package_path="$1"
  local package_name=$(basename "$package_path")
  echo "Processing package: $package_name in $package_path"
  
  # Navigate to the package directory
  cd "$package_path"
  
  # Get the initial audit report
  echo "Getting initial audit report for $package_name..."
  npm_audit_output=$(npm audit --json 2>/dev/null || true)
  echo "$npm_audit_output" > "/tmp/npm-audit-reports/audit-before-$package_name.json"
  
  # Install dependencies if package-lock.json exists but node_modules doesn't
  if [ -f "package-lock.json" ] && [ ! -d "node_modules" ]; then
    echo "Installing dependencies for $package_name..."
    if [ -z "$NPM_ARGS" ]; then
      npm ci
    else
      npm ci $NPM_ARGS
    fi
  fi
  
  # List packages before fix
  echo "Listing packages before fix for $package_name..."
  npm list --json > "/tmp/npm-audit-reports/packages-before-$package_name.json"
  
  # Run npm audit fix
  echo "Running npm audit fix for $package_name..."
  if [ -z "$NPM_ARGS" ]; then
    npm audit fix || echo "Warning: npm audit fix exited with non-zero status for $package_name"
  else
    npm audit fix $NPM_ARGS || echo "Warning: npm audit fix exited with non-zero status for $package_name"
  fi
  
  # Reinstall packages to ensure everything is consistent
  echo "Reinstalling packages for $package_name..."
  if [ -z "$NPM_ARGS" ]; then
    npm ci
  else
    npm ci $NPM_ARGS
  fi
  
  # List packages after fix
  echo "Listing packages after fix for $package_name..."
  npm list --json > "/tmp/npm-audit-reports/packages-after-$package_name.json"
  
  # Get the final audit report
  echo "Getting final audit report for $package_name..."
  npm audit --json > "/tmp/npm-audit-reports/audit-after-$package_name.json" 2>/dev/null || true
  
  # Check if files have been changed
  if git diff --quiet; then
    echo "No changes detected after npm audit fix for $package_name"
  else
    echo "Changes detected after npm audit fix for $package_name"
    # Display a summary of changes
    git diff --name-status
  fi
}

# Function to find all npm packages in the repository
find_npm_packages() {
  find . -name "package.json" -not -path "*/node_modules/*" -not -path "*/\.*" | xargs -n 1 dirname
}

if [ "$MONOREPO" = "true" ]; then
  echo "Running in monorepo mode..."
  
  # Get list of all packages
  PACKAGES=$(find_npm_packages)
  
  # Save the root directory
  ROOT_DIR=$(pwd)
  
  # Create a temporary file to store package paths
  echo "$PACKAGES" > /tmp/package-list.txt
  
  # Process packages in parallel with the specified concurrency
  cat /tmp/package-list.txt | xargs -I{} -P "$CONCURRENCY" sh -c "$(declare -f process_package); process_package '{}'"
  
  # Return to the root directory
  cd "$ROOT_DIR"
  
  # Combine audit reports (this is a simple approach - could be more sophisticated)
  echo "Aggregating audit reports..."
  cat /tmp/npm-audit-reports/audit-before-*.json > /tmp/audit-before.json 2>/dev/null || true
  cat /tmp/npm-audit-reports/audit-after-*.json > /tmp/audit-after.json 2>/dev/null || true
  cat /tmp/npm-audit-reports/packages-before-*.json > /tmp/packages-before.json 2>/dev/null || true
  cat /tmp/npm-audit-reports/packages-after-*.json > /tmp/packages-after.json 2>/dev/null || true
else
  # Original single-package logic
  
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
fi 