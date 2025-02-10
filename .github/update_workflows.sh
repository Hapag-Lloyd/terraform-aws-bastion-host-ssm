#!/usr/bin/env bash
set -euo pipefail

repository_type=""
release_type="auto"
force_execution="false"
repository_path=$(pwd)
dry_run="false"

branch_name="update-workflows-$(date +%s)"

function ensure_prerequisites_or_exit() {
  if ! command -v pre-commit &> /dev/null; then
    echo "pre-commit is not installed. https://github.com/pre-commit/pre-commit"
    exit 1
  fi

  if ! command -v yq &> /dev/null; then
    echo "yq is not installed. https://github.com/mikefarah/yq"
    exit 1
  fi

  if ! command -v gh &> /dev/null; then
    echo "gh is not installed. Please install it from https://cli.github.com/"
    exit 1
  fi
}

function ensure_repo_preconditions_or_exit() {
  if [ "$force_execution" == "true" ]; then
    return
  fi

  # ensure a clean working directory
  if [ -n "$(git status --porcelain)" ]; then
    echo "The working directory is not clean. Please use a clean copy so no unintended changes are merged."
    exit 1
  fi

  # ensure top level directory of the repository
  if [ ! -d .github ]; then
    echo "The script must be executed from the top level directory of the repository."
    exit 1
  fi
}

function show_help_and_exit() {
  echo "Usage: $0 <repository-type> <repository-path> --release-type auto|manual --dry-run"
  echo "repository-type: docker, github-only, maven, python, terraform_module"
  echo "repository-path: the path to the repository to update"
  echo "--release-type: (optional)"
  echo "  auto: the release will be triggered automatically on a push to the default branch"
  echo "  manual: the release will be triggered manually via separate PR, which is created automatically"
  echo "--dry-run: (optional) do not create a PR"

  exit 1
}

function create_commit_and_pr() {
  workflow_tag=$1

  git add .
  git commit -m "update workflows to latest version"
  git push --set-upstream origin "$branch_name"

  body=$(cat <<EOF
# Description

This PR updates all workflows to the latest version.

# Verification

Done by the workflows in this feature branch, except for the release workflow.
EOF
  )

  if [ "$dry_run" == "true" ]; then
    echo "Dry run, no PR created"
  else
    gh pr create --title "ci(deps): update workflows to $workflow_tag" --body "$body" --base main
    gh pr view --web
  fi
}

function ensure_and_set_parameters_or_exit() {
  POSITIONAL_ARGS=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        dry_run="true"
        shift
        ;;
      -f|--force)
        force_execution="true"
        shift
        ;;
      --release-type)
        release_type=$2
        shift
        shift
        ;;
      --*|-*)
        echo "Unknown option $1"
        show_help_and_exit
        ;;
      *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
  done

  set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

    if [ "${#POSITIONAL_ARGS[@]}" -ne 2 ]; then
    show_help_and_exit
  fi

  repository_type=$1
  repository_path=$2

  # check for correct type: docker, github-only, maven, terraform_module
  if [ "$repository_type" != "github-only" ] && [ "$repository_type" != "maven" ] && [ "$repository_type" != "terraform_module" ] && [ "$repository_type" != "docker" ] && [ "$repository_type" != "python" ]; then
    echo "The repository type $repository_type is not supported."
    show_help_and_exit
  fi

  if [ "$repository_type" != "terraform_module" ] && [ "$release_type" == "manual" ]; then
    echo "The release type 'manual' is only supported for terraform_module repositories."
    show_help_and_exit
  fi
}

function setup_cspell() {
  latest_template_path=$1

  # init the dictionaries
  if [ ! -d .config/dictionaries ]; then
    cp -pr "$latest_template_path/.config/dictionaries" .config/
  fi
  # unknown words for copied workflows
  cp -p "$latest_template_path/.config/dictionaries/workflow.txt" .config/dictionaries/

  # the dictionaries for the specific repository types, managed by other repositories
  if [ ! -f .config/dictionaries/maven.txt ]; then
      touch .config/dictionaries/maven.txt
  fi
  if [ ! -f .config/dictionaries/terraform-module.txt ]; then
      touch .config/dictionaries/terraform-module.txt
  fi
  if [ ! -f .config/dictionaries/docker.txt ]; then
      touch .config/dictionaries/docker.txt
  fi
  if [ ! -f .config/dictionaries/simple.txt ]; then
      touch .config/dictionaries/simple.txt
  fi
  if [ ! -f .config/dictionaries/python.txt ]; then
      touch .config/dictionaries/python.txt
  fi

  # project dictionary for the rest, do not overwrite
  if [ ! -f .config/dictionaries/project.txt ]; then
    touch .config/dictionaries/project.txt
  fi
}

ensure_and_set_parameters_or_exit "$@"
ensure_prerequisites_or_exit
ensure_repo_preconditions_or_exit

latest_template_path=$(pwd)

cd "$repository_path" || exit 8
echo "Updating the workflows in $repository_path"

git fetch origin main
git checkout -b "$branch_name" origin/main

# enable nullglob to prevent errors when no files are found
shopt -s nullglob

# basic setup for all types
mkdir -p ".github/workflows/scripts"

cp "$latest_template_path/.github/workflows/default"_* .github/workflows/
cp "$latest_template_path/.github/workflows/scripts/"* .github/workflows/scripts/

cp "$latest_template_path/.github/pull_request_template.md" .github/
cp "$latest_template_path/.github/CODE_OF_CONDUCT.md" .github/
cp "$latest_template_path/.github/CONTRIBUTING.md" .github/
cp "$latest_template_path/.github/renovate.json5" .github/
cp "$latest_template_path/update_workflows.sh" .github/

git ls-files --modified -z .github/workflows/scripts/ .github/update_workflows.sh | xargs -0 -I {} git update-index --chmod=+x {}
git ls-files -z -o --exclude-standard | xargs -0 -I {} git update-index --add --chmod=+x {}

mkdir -p .config
# copy fails if a directory is hit. dictionaries/ is handled in the setup_cspell function
cp -p "$latest_template_path/.config/"*.* .config/
cp -p "$latest_template_path/.config/".*.* .config/

setup_cspell "$latest_template_path"

# we do not have special files for simple GitHub projects, this is handled by the default setup
if [ "$repository_type" != "github-only" ]; then
  cp "$latest_template_path/.github/workflows/${repository_type}"_* .github/workflows/
fi

# setup the release workflow
if [ "$release_type" == "manual" ]; then
  rm .github/workflows/default*release*_callable.yml
fi

#
# Fix the "on" clause in the workflow files, remove all jobs and set a reference to this repository
#
version_info=$(
  cd "$latest_template_path" || exit 9

  # add a reference to this repository which holds the workflow
  commit_sha=$(git rev-parse HEAD)
  tag=$(git describe --tags "$(git rev-list --tags --max-count=1)" || true)

  echo "$commit_sha" "$tag"
)

commit_sha=$(echo "$version_info" | cut -d " " -f 1)
tag=$(echo "$version_info" | cut -d " " -f 2)

# iterate over each file in the directory
for file in .github/workflows/*.yml
do
  base_name=$(basename "$file")

  # remove everything else as we will reference the file in this repository
  sed -i '/jobs:/,$d' "$file"

  file_to_include="uses: Hapag-Lloyd/Workflow-Templates/.github/workflows/$base_name@$commit_sha # $tag"

  # 128 = 132 - 4 spaces (indentation)
  if [ ${#file_to_include} -gt 128 ]; then
    file_to_include="# yamllint disable-line rule:line-length"$'\n'"    $file_to_include"
  fi

  cat >> "$file" <<-EOF
jobs:
  default:
    $file_to_include
    secrets: inherit
EOF

  # add TODOs for the parameters of the workflow
  # false positive, variable is quoted
  # shellcheck disable=SC2086
  if [ "$(yq '.on["workflow_call"] | select(.inputs) != null' $file)" == "true" ]; then
    cp "$file" "$file.bak"
    echo "    with:" >> "$file"

    yq '.on.workflow_call.inputs | keys | .[]' "$file".bak | while read -r input; do
      type=$(yq ".on.workflow_call.inputs.$input.type" "$file".bak)
      required=$(yq ".on.workflow_call.inputs.$input.required" "$file".bak)
      description=$(yq ".on.workflow_call.inputs.$input.description" "$file".bak)
      default="\"my special value\""
      todo="# TODO insert correct value for $input"$'\n'"      "

      case "$input" in
        "python-version")
          # no expansion of the variable as it is a string we want to keep
          # shellcheck disable=SC2016
          default='${{ vars.PYTHON_VERSION }}'
          todo=""
          ;;
        "python-versions")
          # no expansion of the variable as it is a string we want to keep
          # shellcheck disable=SC2016
          default='${{ vars.PYTHON_VERSIONS }}'
          todo=""
          ;;
        "pypi-url")
          # no expansion of the variable as it is a string we want to keep
          # shellcheck disable=SC2016
          default='${{ vars.PYPI_URL }}'
          todo=""
          ;;
        *)
          ;;
      esac

      cat >> "$file" <<-EOF
      $todo# type: $type
      # required: $required
      # description: $description
      $input: $default
EOF
    done

    rm "$file.bak"
  fi

  # remove the comment char for all lines between USE_REPOSITORY and /USE_REPOSITORY in the file
  sed -i '/USE_REPOSITORY/,/\/USE_REPOSITORY/s/^#//' "$file"

  # remove the everything between USE_WORKFLOW and /USE_WORKFLOW
  sed -i '/USE_WORKFLOW/,/\/USE_WORKFLOW/d' "$file"

  # remove the marker lines
  sed -i '/USE_REPOSITORY/d' "$file"
  sed -i '/\/USE_REPOSITORY/d' "$file"
  sed -i '/USE_WORKFLOW/d' "$file"
  sed -i '/\/USE_WORKFLOW/d' "$file"
done

#
# Remove the prefix from the workflow files
#
prefixes=("default_" "terraform_module_" "docker_" "maven_" "python_")

# iterate over each file in the directory
for file in .github/workflows/*.yml
do
  # get the base name of the file
  base_name=$(basename "$file")

  # iterate over each prefix
  for prefix in "${prefixes[@]}"
  do
    # check if the file name starts with the prefix
    if [[ $base_name == $prefix* ]]; then
      # remove the prefix
      new_name=${base_name#"$prefix"}

      # rename the file
      mv "$file" ".github/workflows/$new_name"

      # break the loop as the prefix has been found and removed
      break
    fi
  done
done

#
# Remove the suffix from the workflow files
#
suffixes=("_callable.yml")

# iterate over each file in the directory
for file in .github/workflows/*.yml
do
  # get the base name of the file
  base_name=$(basename "$file")

  # iterate over each suffix
  for suffix in "${suffixes[@]}"
  do
    # check if the file name starts with the prefix
    if [[ $base_name == *$suffix ]]; then
      # remove the suffix
      new_name="${base_name%"$suffix"}.yml"

      # rename the file
      mv "$file" ".github/workflows/$new_name"

      # break the loop as the suffix has been found and removed
      break
    fi
  done
done

pre-commit install -c .config/.pre-commit-config.yaml

create_commit_and_pr "$tag"

# do not remove the latest template path if it was provided as a parameter
if [ -z "$local_workflow_path" ]; then
  rm -rf "$latest_template_path"
fi
