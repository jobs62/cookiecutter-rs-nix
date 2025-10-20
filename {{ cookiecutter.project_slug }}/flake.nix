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

        craneLib = crane.mkLib pkgs;
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
            "rust-std"
            "rustfmt"
            "clippy"
            "rust-docs"
          ]);

        cargoArtifacts = craneLibLlvmTools.buildDepsOnly commonArgs;

        {{ cookiecutter.project_slug }} = craneLibLlvmTools.buildPackage (commonArgs // {
            inherit cargoArtifacts;
        });
      in {
        packages = {
            default = {{ cookiecutter.project_slug }};
        };

        checks = {
          inherit {{ cookiecutter.project_slug }};

          {{ cookiecutter.project_slug }}-clippy = craneLibLlvmTools.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          {{ cookiecutter.project_slug }}-fmt = craneLibLlvmTools.cargoFmt (commonArgs // {
            inherit src;
          });
        };

        apps.default = flake-utils.lib.mkApp {
            drv = {{ cookiecutter.project_slug }};
        };

        devShells.default = craneLibLlvmTools.devShell {
          checks = self.checks.${system};

          packages = [
            pkgs.rust-analyzer
          ];
        };
      }
    );
}
