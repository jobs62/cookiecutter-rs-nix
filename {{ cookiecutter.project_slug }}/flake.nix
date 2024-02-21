{
  description = "{{ cookiecutter.description }}";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    crane = {
        url = "github:ipetkov/crane";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        inherit (pkgs) lib;

        craneLib = crane.lib.${system};
        src = craneLib.cleanCargoSource (craneLib.path ./.);

        commonArgs = {
          inherit src;
          strictDeps = true;
        };

        craneLibLlvmTools = craneLib.overrideToolchain
          (fenix.packages.${system}.complete.withComponents [
            "cargo"
            "llvm-tools"
            "rustc"
          ]);

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        {{ cookiecutter.project_slug }} = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
        });
      in {
        packages = {
            default = {{ cookiecutter.project_slug }};
        };

        checks = {
          inherit {{ cookiecutter.project_slug }};

          {{ cookiecutter.project_slug }}-clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          {{ cookiecutter.project_slug }}-fmt = craneLib.cargoFmt (commonArgs // {
            inherit src;
          });
        };

        apps.default = flake-utils.lib.mkApp {
            drv = {{ cookiecutter.project_slug }};
        };

        devShells.default = craneLib.devShell {
          packages = [
            pkgs.rust-analyzer
          ];
        };
      }
    );
}
