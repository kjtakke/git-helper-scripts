#!/bin/bash

alias git-log="git log --graph --all --decorate --pretty=format:'%C(yellow)%h%Creset %Cgreen%ad%Creset %C(auto)%d%Creset %s' --date=iso"

# Git commit with message
git-commit() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: git-commit <message>"
    echo "  Commits all staged and unstaged changes with the provided message."
    return 0
  fi

  git add .
  git commit -am "$1"
}

# Git push with message
git-push() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: git-push <message>"
    echo "  Commits all staged and unstaged changes with the provided message and pushes to remote."
    return 0
  fi

  git add .
  git commit -am "$1"
  git push
}

# Git stash with options
git-stash() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: git-stash [--clear | --apply | --update | --list]"
    echo "  --clear   Clears all stashes and resets the working directory."
    echo "  --apply   Applies the most recent stash."
    echo "  --update  Updates (restashes) current changes with the latest stash."
    echo "  --list    Shows the list of all stashes."
    echo "  (No args) Stashes current changes."
    return 0
  fi

  case "$1" in
    --clear)
      echo "Clearing all stashes..."
      git stash clear
      git reset --hard
      ;;
    --apply)
      echo "Applying latest stash..."
      git stash apply
      ;;
    --update)
      echo "Updating stash with current changes..."
      git stash apply
      git add .
      git stash
      ;;
    --list)
      echo "Listing all stashes..."
      git stash list
      ;;
    *)
      echo "Stashing changes..."
      git stash
      ;;
  esac
}


# Git merge with optional branch (default: main)
git-merge() {
  # Help menu
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: git-merge [--branch <branch>] [--abort]"
    echo ""
    echo "Options:"
    echo "  --branch <branch>  Specify the branch to merge from (default: main)."
    echo "  --abort            Abort the current merge (if one is in progress)."
    echo "  -h, --help         Show this help message."
    echo ""
    echo "Examples:"
    echo "  git-merge                  # Merges origin/main into current branch"
    echo "  git-merge --branch develop # Merges origin/develop"
    echo "  git-merge --abort          # Aborts the current merge"
    return 0
  fi

  # Abort option
  if [[ "$1" == "--abort" ]]; then
    echo "Aborting current merge..."
    git merge --abort
    return $?
  fi

  # Default branch
  local branch="main"

  # Parse branch argument
  if [[ "$1" == "--branch" && -n "$2" ]]; then
    branch="$2"
  elif [[ -n "$1" && "$1" != "--branch" ]]; then
    branch="$1"
  fi

  echo "Pulling and fetching latest changes..."
  git pull && git fetch

  echo "Merging origin/${branch} into current branch..."
  git merge "origin/${branch}"
}

# Git pull and merge current branch into a target branch (default: main)
git-pull-request() {
  local target_branch="main"
  local FORCE_STRATEGY=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --branch)
        target_branch="$2"
        shift 2
        ;;
      --force)
        if [[ "$2" != "ours" && "$2" != "theirs" ]]; then
          echo "Error: --force must be followed by 'ours' or 'theirs'."
          return 1
        fi
        FORCE_STRATEGY="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: git-pull-request [--branch <branch>] [--force <ours|theirs>]"
        echo ""
        echo "Merges changes from the current branch into the target branch (default: main)."
        echo "Options:"
        echo "  --branch <branch>   Specify a different target branch instead of 'main'."
        echo "  --force <ours|theirs> Resolve all conflicts by keeping 'ours' or 'theirs'."
        echo "  -h, --help          Show this help message."
        echo ""
        echo "Examples:"
        echo "  git-pull-request                  # Merges current branch into main"
        echo "  git-pull-request --branch develop # Merges current branch into develop"
        echo "  git-pull-request --force theirs   # Merges with all changes from incoming branch"
        return 0
        ;;
      *)
        shift
        ;;
    esac
  done

  # Store the branch we started on
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ "$current_branch" == "$target_branch" ]]; then
    echo "You are already on '$target_branch'. Nothing to merge."
    return 1
  fi

  echo "Fetching latest changes..."
  git fetch --all
  git pull origin "$current_branch"

  echo "Checking out '$target_branch'..."
  if ! git checkout "$target_branch"; then
    echo "Failed to checkout '$target_branch'. Returning to '$current_branch'."
    git checkout "$current_branch"
    return 1
  fi
  git pull origin "$target_branch"

  echo "Merging ${current_branch} into ${target_branch}..."
  if [[ -n "$FORCE_STRATEGY" ]]; then
    if ! git merge -X "$FORCE_STRATEGY" "$current_branch"; then
      echo "Forced merge using strategy: $FORCE_STRATEGY."
    fi
  else
    if ! git merge "$current_branch"; then
      echo "Merge conflict detected!"
      echo "Resetting '$target_branch' to match origin/${target_branch}..."
      git reset --hard "origin/${target_branch}"
      echo "Returning to '${current_branch}'..."
      git checkout "$current_branch"
      return 1
    fi
  fi

  echo "Pushing updated '$target_branch' to origin..."
  git push origin "$target_branch"

  echo "Returning to ${current_branch}..."
  git checkout "$current_branch"
}

# Git branch manager
git-branch() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: git-branch <branch>"
    echo ""
    echo "Checks out the given branch if it exists locally or remotely."
    echo "If the branch does not exist, it is created locally and pushed to origin with upstream set."
    echo ""
    echo "Examples:"
    echo "  git-branch feature-x"
    echo "  git-branch -h"
    return 0
  fi

  local branch="$1"

  echo "Checking for existing branch '$branch'..."

  # Check if the branch exists locally
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Branch '$branch' exists locally. Checking out..."
    git checkout "$branch"
    return
  fi

  # Check if the branch exists remotely
  if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
    echo "Branch '$branch' exists on remote. Checking out and tracking..."
    git checkout -b "$branch" "origin/$branch"
    return
  fi

  # If branch does not exist, create and push
  echo "Branch '$branch' does not exist. Creating and pushing to origin..."
  git checkout -b "$branch"
  git push --set-upstream origin "$branch"
}


alias d-t="docker exec -it tedge /bin/bash"
alias d-g="docker exec -it rf-tac-go /bin/bash"
alias d-d="docker exec -it rf-tac-db /bin/bash"
alias mqtt-sub="mosquitto_sub -h localhost -p 1883 -t '#' -F '%I :: %t :: %p'"
docker-exec() {
    if [ -z "$1" ]; then
        echo "Usage: docker-exec <container_name_or_id>"
        return 1
    fi
    docker exec -it "$1" /bin/bash
}

git-reset() {
  local USE_ORIGIN=false
  local HARD_RESET=false
  local BRANCH=""
  
  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --origin)
        USE_ORIGIN=true
        ;;
      --hard)
        HARD_RESET=true
        ;;
      -h|--help)
        echo "Usage: git-rest [--origin] [--hard] [<branch>]"
        echo "  --origin   Reset against remote (origin/<branch>)."
        echo "  --hard     Force hard reset (default is soft reset)."
        echo "  <branch>   Optional branch name (default: current branch)."
        echo "Examples:"
        echo "  git-rest --origin --hard main"
        echo "  git-rest --hard            # Hard reset to current branch (local)"
        echo "  git-rest --origin develop  # Soft reset to origin/develop"
        return 0
        ;;
      *)
        BRANCH="$arg"
        ;;
    esac
  done

  # Determine the branch if not provided
  if [[ -z "$BRANCH" ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ -z "$BRANCH" ]]; then
      echo "Error: Could not determine current branch."
      return 1
    fi
  fi

  # Build target (local or remote)
  local TARGET="$BRANCH"
  if $USE_ORIGIN; then
    TARGET="origin/$BRANCH"
    echo "Using remote branch: $TARGET"
    git fetch origin "$BRANCH"
  else
    echo "Using local branch: $TARGET"
  fi

  # Determine reset mode
  local RESET_MODE="reset"
  if $HARD_RESET; then
    echo "Performing HARD reset on $TARGET..."
    git reset --hard "$TARGET"
  else
    echo "Performing SOFT reset on $TARGET..."
    git reset "$TARGET"
  fi
}

git-merge-force() {
  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 2 ]]; then
    echo "Usage: git-merge-force <branch> <ours|theirs>"
    echo "  <branch>    The branch to merge into the current branch."
    echo "  ours        Keep all current branch changes (ignore incoming)."
    echo "  theirs      Keep all incoming branch changes (ignore current)."
    echo ""
    echo "Example:"
    echo "  git-merge-force develop ours"
    return 0
  fi

  local MERGE_BRANCH="$1"
  local STRATEGY="$2"

  if [[ "$STRATEGY" != "ours" && "$STRATEGY" != "theirs" ]]; then
    echo "Error: Strategy must be 'ours' or 'theirs'."
    return 1
  fi

  echo "Merging branch '$MERGE_BRANCH' into current branch, accepting all '$STRATEGY' changes..."
  git fetch origin "$MERGE_BRANCH"

  git merge -X "$STRATEGY" "$MERGE_BRANCH"
}

git-rollback() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: git-rollback [--list | --commit <index>]"
    echo ""
    echo "Options:"
    echo "  --list            Lists recent commits with index numbers."
    echo "  --commit <index>  Rolls back (hard reset) to the commit with the given index."
    echo ""
    echo "Examples:"
    echo "  git-rollback --list"
    echo "  git-rollback --commit 2"
    return 0
  fi

  case "$1" in
    --list)
      echo "Listing recent commits..."
      git log --oneline -n 20 | nl -w2 -s'  '
      ;;
    --commit)
      if [[ -z "$2" ]]; then
        echo "Error: No commit index specified. Use --list to see commit indices."
        return 1
      fi
      COMMIT_HASH=$(git log --oneline -n 20 | sed -n "${2}p" | awk '{print $2 ? $1 : ""}')
      if [[ -z "$COMMIT_HASH" ]]; then
        echo "Error: Invalid index. Use --list to see available commits."
        return 1
      fi
      echo "Rolling back to commit $COMMIT_HASH..."
      git reset --hard "$COMMIT_HASH"
      ;;
    *)
      echo "Invalid option. Use --help for usage."
      return 1
      ;;
  esac
}


git-help() {
  if [[ "$1" == "-i" || "$1" == "--list" ]]; then
    echo "Available Git Helper Functions:"
    echo "  git-commit"
    echo "  git-push"
    echo "  git-stash"
    echo "  git-merge"
    echo "  git-pull-request"
    echo "  git-branch"
    echo "  git-reset"
    echo "  git-merge-force"
    echo "  git-rollback"
    return 0
  fi

  cat <<'EOF'
Custom Git Helper Commands
==========================

git-commit <message>
  Commits all staged and unstaged changes with the provided message.
  Example:
    git-commit "Fix bug in module"

git-push <message>
  Commits all staged and unstaged changes with the provided message and pushes to remote.
  Example:
    git-push "Add new feature"

git-stash [--clear | --apply | --update | --list]
  --clear   Clears all stashes and resets the working directory.
  --apply   Applies the most recent stash.
  --update  Updates (restashes) current changes with the latest stash.
  --list    Shows the list of all stashes.
  (No args) Stashes current changes.
  Example:
    git-stash --list

git-merge [--branch <branch>] [--abort]
  --branch <branch>  Specify the branch to merge from (default: main).
  --abort            Abort the current merge (if one is in progress).
  Example:
    git-merge --branch develop

git-pull-request [--branch <branch>] [--force <ours|theirs>]
  Merges the current branch into the target branch (default: main).
  If a merge conflict occurs:
    - With --force, automatically resolve conflicts by preferring 'ours' or 'theirs'.
    - Without --force, the target branch is reset to match origin/<branch>.
  Options:
    --branch <branch>    Specify a different target branch instead of 'main'.
    --force <ours|theirs> Automatically resolve conflicts with the chosen strategy.
  Example:
    git-pull-request --branch develop --force ours

git-branch <branch>
  Checks out the branch if it exists locally or remotely.
  If the branch doesn't exist, it creates and pushes it to origin.
  Example:
    git-branch feature-x

git-reset [--origin] [--hard] [<branch>]
  --origin   Reset against remote (origin/<branch>).
  --hard     Force hard reset (default is soft reset).
  <branch>   Optional branch name (default: current branch).
  Example:
    git-reset --origin --hard main

git-merge-force <branch> <ours|theirs>
  Merges a branch into the current branch, accepting all 'ours' or 'theirs' changes.
  Example:
    git-merge-force develop ours

git-rollback [--list | --commit <index>]
  --list           Lists recent commits (20 by default) with an index number.
  --commit <index> Resets (hard rollback) to the commit with the given index from --list.
  Example:
    git-rollback --list
    git-rollback --commit 2
EOF
}
