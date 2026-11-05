#!/usr/bin/env bash
set -euo pipefail

cargo generate-lockfile
nix flake lock
nix fmt
