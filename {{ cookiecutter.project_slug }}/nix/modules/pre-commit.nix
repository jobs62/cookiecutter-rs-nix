# L2 layer: pre-commit hooks (installed in the devshell, run as a flake check).
# The treefmt hook is automatically wired to the treefmt-nix wrapper
# (see modules/fmt.nix) when both flakeModules are imported.
#
# Clippy deliberately stays OUT of pre-commit: it belongs to the compile
# loop and the CI gate, not to every commit.
{
  perSystem = {...}: {
    pre-commit.settings.hooks.treefmt.enable = true;
  };
}
