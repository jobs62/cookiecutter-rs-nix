# L2 layer: fast formatting, enforced by `nix fmt` and pre-commit.
{
  perSystem = {...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      programs.rustfmt.enable = true;
      programs.taplo.enable = true;
    };
  };
}
