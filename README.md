# Git Helper Functions

This repository contains a set of custom `git-xxx` functions that simplify common Git workflows. These functions can be sourced in your `.zshrc` or `.bashrc` to extend Git with powerful shortcuts.

## Available Commands

**git-log**
applies a date formatted git log tree

**git-commit `<message>`**  
Commits all staged and unstaged changes with the provided message.  
Example:  
`git-commit "Fix bug in module"`

**git-push `<message>`**  
Commits all staged and unstaged changes with the provided message and pushes to the remote branch.  
Example:  
`git-push "Add new feature"`

**git-stash `[--clear | --apply | --update | --list]`**  
An enhanced stash command with additional options:

- `--clear` – Clears all stashes and resets the working directory.
    
- `--apply` – Applies the most recent stash.
    
- `--update` – Updates the stash with current changes.
    
- `--list` – Lists all stashes.  
    Example:  
    `git-stash --list`
    

**git-merge `[--branch <branch>] [--abort]`**  
Merges a branch into the current branch (defaults to `main`).

- `--branch <branch>` – Merge from the specified branch.
    
- `--abort` – Abort an in-progress merge.  
    Example:  
    `git-merge --branch develop`
    

**git-pull-request `[--branch <branch>] [--force <ours|theirs>]`**  
Merges the current branch into the target branch (default `main`) and pushes the result.

- `--branch <branch>` – Merge into the specified branch.
    
- `--force ours` – Resolve all conflicts by keeping current branch changes.
    
- `--force theirs` – Resolve all conflicts by keeping incoming branch changes.  
    Example:  
    `git-pull-request --branch develop --force ours`
    

**git-branch `<branch>`**  
Checks out a branch if it exists, or creates and pushes it if it does not.  
Example:  
`git-branch feature-x`

**git-reset `[--origin] [--hard] [<branch>]`**  
Resets your branch to a given state.

- `--origin` – Reset against `origin/<branch>`.
    
- `--hard` – Perform a hard reset.  
    Example:  
    `git-reset --origin --hard main`
    

**git-merge-force `<branch> <ours|theirs>`**  
Merges a branch into the current branch and auto-resolves conflicts by preferring either `ours` or `theirs`.  
Example:  
`git-merge-force develop ours`

**git-rollback `[--list | --commit <index>]`**  
Rollback to a specific commit from a list of recent commits.

- `--list` – Lists the last 20 commits with an index.
    
- `--commit <index>` – Resets to the commit at the specified index.  
    Example:  
    `git-rollback --list`  
    `git-rollback --commit 2`
    

**git-help `[-i | --index]`**  
Displays help for all commands or just their names.

- `-i` – Show only the function names.  
    Example:  
    `git-help`  
    `git-help -i`

## Installation

1.  Clone this repository:  
    `git clone <repo-url> git-helpers`
    
2.  Add the functions to your shell configuration:  
    `cat git-helpers/git-functions.sh >> ~/.zshrc`  
    or source them directly:  
    `source /path/to/git-helpers/git-functions.sh`
    
3.  Reload your shell:  
    `source ~/.zshrc`
    

## Why Use These?

- Speeds up repetitive Git workflows.
    
- Provides enhanced stash, rollback, and merge functionality.
    
- Useful for teams that want consistent Git command shortcuts.
    

## Next Steps

To see all available commands at any time:  
`git-help`
