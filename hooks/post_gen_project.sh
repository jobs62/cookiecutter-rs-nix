#!/usr/bin/env bash
set -euo pipefail

nix fmt

# Start version control immediately so the pre-commit hooks land on a real repo.
if command -v git >/dev/null 2>&1; then
  git init -q
  # Scaffold a repo-local identity only when the user has none, so the
  # initial commit is deterministic on fresh machines and CI runners.
  if ! git config user.email >/dev/null; then
    git config user.name "cookiecutter-rs-nix"
    git config user.email "cookiecutter@localhost"
  fi
  git add -A
  git commit -qm "chore: initial commit from cookiecutter-rs-nix"
fi
