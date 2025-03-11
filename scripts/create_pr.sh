#!/bin/sh
set -e

# Get inputs
GITHUB_TOKEN="$1"
BRANCH="$2"
DEFAULT_BRANCH="$3"
COMMIT_TITLE="$4"
LABELS="$5"
ASSIGNEES="$6"

# Extract repository information from the GITHUB_REPOSITORY environment variable
GITHUB_REPOSITORY_OWNER=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f 1)
GITHUB_REPOSITORY_NAME=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f 2)

echo "==== Creating pull request ===="
echo "Repository: ${GITHUB_REPOSITORY}"
echo "Branch: ${BRANCH}"

# Check if there are changes to commit
if git diff --quiet; then
  echo "No changes to commit"
  exit 0
fi

# Get default branch if not provided
if [ -z "$DEFAULT_BRANCH" ]; then
  DEFAULT_BRANCH=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}" | \
    jq -r '.default_branch')
  echo "Default branch: ${DEFAULT_BRANCH}"
fi

# Create and checkout new branch
git checkout -b "${BRANCH}"

# Add and commit changes
git add .
git commit -m "${COMMIT_TITLE}"

# Generate a report from the audit results
echo "Generating PR body..."
PR_BODY=$(cat <<EOF
# npm audit fix report

This pull request fixes vulnerabilities in npm packages.

## Summary of changes

$(git diff --name-status "${DEFAULT_BRANCH}" | sed 's/^/- /')

## Details

$(jq -r 'if has("vulnerabilities") then .vulnerabilities | keys[] as $k | "- \($k): \(.[$k] | .severity)" else "No vulnerabilities found" end' /tmp/audit-before.json 2>/dev/null || echo "No initial audit data available")

This PR was created automatically by the npm-audit-fix-action.
EOF
)

# Push changes
echo "Pushing changes..."
git push --set-upstream origin "${BRANCH}"

# Create PR
echo "Creating PR..."
PR_URL=$(curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls" \
  -d "{\"title\":\"${COMMIT_TITLE}\", \"body\":\"${PR_BODY}\", \"head\":\"${BRANCH}\", \"base\":\"${DEFAULT_BRANCH}\"}" | \
  jq -r '.html_url')

if [ -z "$PR_URL" ] || [ "$PR_URL" = "null" ]; then
  echo "Failed to create PR"
  exit 1
fi

echo "PR created: ${PR_URL}"

# Add labels if provided
if [ -n "$LABELS" ]; then
  PR_NUMBER=$(echo "$PR_URL" | sed -E 's|.*/pull/([0-9]+)$|\1|')
  echo "Adding labels to PR #${PR_NUMBER}..."
  
  # Convert comma-separated labels to JSON array
  LABELS_JSON="["
  for label in $(echo "$LABELS" | tr ',' ' '); do
    LABELS_JSON="${LABELS_JSON}\"${label}\","
  done
  LABELS_JSON="${LABELS_JSON%,}]"
  
  curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/labels" \
    -d "{\"labels\":${LABELS_JSON}}"
fi

# Add assignees if provided
if [ -n "$ASSIGNEES" ]; then
  PR_NUMBER=$(echo "$PR_URL" | sed -E 's|.*/pull/([0-9]+)$|\1|')
  echo "Adding assignees to PR #${PR_NUMBER}..."
  
  # Convert comma-separated assignees to JSON array
  ASSIGNEES_JSON="["
  for assignee in $(echo "$ASSIGNEES" | tr ',' ' '); do
    ASSIGNEES_JSON="${ASSIGNEES_JSON}\"${assignee}\","
  done
  ASSIGNEES_JSON="${ASSIGNEES_JSON%,}]"
  
  curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/assignees" \
    -d "{\"assignees\":${ASSIGNEES_JSON}}"
fi

echo "Done!" 