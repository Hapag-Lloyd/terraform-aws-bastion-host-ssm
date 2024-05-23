#!/usr/bin/env bash
set -euo pipefail

#
# This script updates the current repository with the latest version of the templates. It creates a new branch and a pull request.
#

function ensure_dependencies_or_exit() {
  if ! command -v gh &> /dev/null; then
    echo "gh is not installed. Please install it from https://cli.github.com/"
    exit 1
  fi
}

function ensure_repo_preconditions_or_exit() {
  # ensure main branch
  if [ "$(git branch --show-current)" != "main" ]; then
    echo "The current branch is not main. Please switch to the main branch."
    exit 1
  fi

  # ensure a clean working directory
  if [ -n "$(git status --porcelain)" ]; then
    echo "The working directory is not clean. Please use a clean copy so no unintended changes are merged."
    exit 1
  fi
}

function create_and_show_pr_for_init_branch() {
  local branch_name=$1

  if git branch | grep -q "$branch_name"; then
    git checkout "$branch_name"

    title=$(head -n1 pr-description.md)
    body=$(tail -n2 pr-description.md)

    rm pr-description.md
    git add .
    git commit -m "remove the PR description"
    git push

    gh pr create --title "$title" --body "$body" --base main --head "$branch_name"
    gh pr view --web
  fi
}

ensure_dependencies_or_exit
ensure_repo_preconditions_or_exit

latest_template_path=$(mktemp -d -t repository-template-XXXXX)
new_branch_name=$(basename "$latest_template_path")

# clone the default branch to get the latest version of the template files
gh repo clone https://github.com/Hapag-Lloyd/Repository-Template-Maven.git "$latest_template_path"

# create a new branch to update the templates
git checkout -b "$new_branch_name"

# update issue templates
cp -r "$latest_template_path/.github/ISSUE_TEMPLATE" .github/

# update pull request template
cp "$latest_template_path/.github/PULL_REQUEST_TEMPLATE.md" .github/

# update contributing guidelines
cp "$latest_template_path/.github/CONTRIBUTING.md" .github/

# update the update scripts
cp "$latest_template_path/.github"/update_*.sh .github/

# create a commit, push it and open a pull request
git add .github
git commit -m "chore: update project templates"
git push --set-upstream origin "$new_branch_name"

gh pr create --title "chore: update project templates" --body "This PR updates the project templates." --base main --head "$new_branch_name"

echo "The project templates have been updated. Please review and merge the pull request."
gh pr view --web

# create PR to initialize the CODEOWNERS file
branch_name="kayma/init-codeowners"

if git branch | grep -q "$branch_name"; then
  git checkout "$branch_name"

  title=$(head -n1 pr-description.md)
  body=$(tail -n2 pr-description.md)

  rm pr-description.md
  git add .
  git commit -m "remove the PR description"
  git push

  gh pr create --title "$title" --body "$body" --base main --head "$branch_name"
  gh pr view --web
fi

# initialize the LICENSE and CODEOWNERS file

# find all init- branches
init_branches=$(git branch | grep "init-")

for init_branch in $init_branches; do
  create_and_show_pr_for_init_branch "$init_branch"
done

rm -rf "$latest_template_path"
