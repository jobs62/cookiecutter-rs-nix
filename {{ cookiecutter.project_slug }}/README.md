# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

## The loop stack

Feedback is the point. Each layer runs faster and more often than the next,
and each layer filters what the previous one let through:

| Layer | When | Command / mechanism |
|---|---|---|
| L1 editor loop | continuously | `direnv allow` → toolchain + rust-analyzer |
| L2 commit | every commit | pre-commit: treefmt (nix, rust, toml) |
| L3 compile/test loop | while coding | `cargo clippy --workspace`, `cargo nextest run` |
| L4 CI gate | every push | `nix flake check -L` (per-crate build, clippy -D warnings, nextest, fmt, cargoAudit, hakari verify) |
| L5 dependency updates | weekly | Renovate PRs (flake.lock + Cargo.lock) |

Everything is wired through [flake-parts](https://flake.parts) modules in
`nix/modules/` — one module per layer, no monolith.

### Workspace layout

- `crates/<name>/` — one crate per directory; the workspace uses the wildcard
  `members = ["crates/*"]`, so a new crate is: create the directory + add a
  `buildPackage` block in `nix/modules/rust.nix` mirroring the existing one.
- `crates/workspace-hack/` — [cargo-hakari](https://docs.rs/cargo-hakari)
  output; unifies shared dependency builds across crates for maximum cache
  reuse (Nix side builds each crate as its own derivation over one shared
  dependency build). Never edit by hand: `cargo hakari generate` — CI fails if
  it drifts.

### Lints

Workspace-level clippy lints (strict, panic/failure-averse) are defined in the
root `Cargo.toml`; every crate opts in with `lints.workspace = true`. Test
relaxations live in `clippy.toml`. Suppressions must be
`#[expect(..., reason = "...")]`, never bare `#[allow]`.
