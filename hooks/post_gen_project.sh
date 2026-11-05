#!/usr/bin/env bash
set -euo pipefail

nix fmt

# Start version control immediately so the pre-commit hooks land on a real repo.
if command -v git >/dev/null 2>&1; then
  git init -q
  git add -A
  git commit -qm "chore: initial commit from cookiecutter-rs-nix"
fi
