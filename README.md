# Docker npm audit fix Action

This action runs `npm audit fix` and creates a pull request. It is a Docker-based alternative to [ybiquitous/npm-audit-fix-action](https://github.com/ybiquitous/npm-audit-fix-action).

## Features

- Runs `npm audit fix` to automatically fix vulnerabilities in npm packages
- Creates a pull request with the changes
- Adds labels and assignees to the pull request
- Generates a detailed report of the vulnerabilities fixed
- Can be configured to run on a schedule or manually

## Usage

Create a workflow file in your repository (e.g., `.github/workflows/npm-audit-fix.yml`):

```yaml
name: npm audit fix

on:
  schedule:
    - cron: "0 0 * * *"  # Run daily at midnight
  workflow_dispatch:     # Allow manual trigger

jobs:
  npm-audit-fix:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v3
      - uses: frozander/docker-npm-audit-fix-action@v1
```

### Inputs

| Name             | Description                          | Default                                        |
| ---------------- | ------------------------------------ | ---------------------------------------------- |
| `github_token`   | GitHub token                         | `${{ github.token }}`                          |
| `github_user`    | GitHub user name for commit changes  | `${{ github.actor }}`                          |
| `github_email`   | GitHub user email for commit changes | `${{ github.actor }}@users.noreply.github.com` |
| `branch`         | Created branch                       | `npm-audit-fix-action/fix`                     |
| `default_branch` | Default branch                       | n/a                                            |
| `commit_title`   | Commit and PR title                  | `build(deps): npm audit fix`                   |
| `labels`         | PR labels (comma-separated)          | `dependencies, javascript, security`           |
| `assignees`      | PR assignees (comma-separated)       | n/a                                            |
| `npm_args`       | Arguments for the `npm` command      | n/a                                            |
| `path`           | Path to the project root directory   | `.`                                            |

### Using a personal access token

If you want to run your CI with pull requests created by this action, you may need to set a personal access token instead of the GitHub's default token:

```yaml
with:
  github_token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
```

The reason is that the default token does not have enough permissions to trigger CI. See also the [GitHub documentation](https://docs.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token#permissions-for-the-github_token) about token permissions.

## Docker vs. JavaScript Action

This action is functionally identical to the original [ybiquitous/npm-audit-fix-action](https://github.com/ybiquitous/npm-audit-fix-action), but it uses Docker instead of JavaScript. This approach has some advantages:

- Containerized environment isolation
- No need to manage Node.js dependencies in the action itself
- Potentially easier to understand and modify the shell script implementation

## License

[MIT](LICENSE) 