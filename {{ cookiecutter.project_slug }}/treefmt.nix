{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.alejandra.enable = true;
  programs.taplo.enable = true;
  programs.rustfmt.enable = true;
}
