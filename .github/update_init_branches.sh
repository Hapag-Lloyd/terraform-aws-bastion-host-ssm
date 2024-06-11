#!/usr/bin/env bash
set -euo pipefail

#
# This script rebases all init branches on the main branch.
#

git checkout main
git pull

# for all init branches
for branch in $(git branch --list "init-*"); do
  git checkout "$branch"
  git merge main
  git push
done
