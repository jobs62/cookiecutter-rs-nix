# L3/L4 layer: the compile/test loop and the machine-evaluable CI gate.
# One derivation per workspace crate over a single shared dependency build:
# touching one crate never rebuilds dependencies or the other crates.
{
  perSystem = {
    config,
    inputs,
    lib,
    pkgs,
    self',
    system,
    ...
  }: let
    craneLib = inputs.crane.mkLib pkgs;

    # Toolchain version is pinned through flake.lock; bump = Renovate PR.
    craneLibToolchain = craneLib.overrideToolchain
      (inputs.fenix.packages.${system}.complete.withComponents [
        "cargo"
        "clippy"
        "llvm-tools"
        "rust-docs"
        "rust-std"
        "rustc"
        "rustfmt"
      ]);

    src = craneLibToolchain.cleanCargoSource (craneLibToolchain.path ../..);

    commonArgs = {
      inherit src;
      strictDeps = true;
      buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.libiconv
      ];
    };

    # Dependencies of the WHOLE workspace, built once and shared.
    # cargo-hakari (workspace-hack crate) keeps feature sets unified so
    # this stays cache-valid across all crates.
    cargoArtifacts = craneLibToolchain.buildDepsOnly commonArgs;

    workspaceVersion = (builtins.fromTOML (builtins.readFile ../../Cargo.toml)).workspace.package.version;

    individualCrateArgs =
      commonArgs
      // {
        inherit cargoArtifacts;
        inherit workspaceVersion;
        # Tests run once, partitioned, via cargoNextest below.
        doCheck = false;
      };

    # Minimal source per crate: workspace manifests + workspace-hack + the crate.
    fileSetForCrate = crate:
      lib.fileset.toSource {
        root = ../..;
        fileset = lib.fileset.unions [
          ../../Cargo.toml
          ../../Cargo.lock
          (craneLibToolchain.fileset.commonCargoSources ../../crates/workspace-hack)
          (craneLibToolchain.fileset.commonCargoSources crate)
        ];
      };

    crateName = "{{ cookiecutter.project_slug }}";

    app = craneLibToolchain.buildPackage (individualCrateArgs
      // {
        pname = crateName;
        cargoExtraArgs = "-p ${crateName}";
        src = fileSetForCrate ../../crates/${crateName};
      });
  in {
    packages.default = app;

    checks = {
      inherit app;

      # The workspace lints are actually enforced (deny warnings).
      workspace-clippy = craneLibToolchain.cargoClippy (commonArgs
        // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });

      # Fast, partitioned test runner; --no-tests=pass keeps fresh workspaces green.
      workspace-nextest = craneLibToolchain.cargoNextest (commonArgs
        // {
          inherit cargoArtifacts;
          partitions = 1;
          partitionType = "count";
          cargoNextestPartitionsExtraArgs = "--no-tests=pass";
        });

      workspace-audit = craneLibToolchain.cargoAudit {
        inherit src;
        advisory-db = inputs.advisory-db;
      };

      # Tripwire: the workspace-hack crate must never drift by hand.
      workspace-hakari = craneLibToolchain.mkCargoDerivation {
        inherit src;
        pname = "workspace-hakari";
        cargoArtifacts = null;
        doInstallCargoArtifacts = false;

        buildPhaseCargoCommand = ''
          cargo hakari generate --diff       # workspace-hack Cargo.toml is up-to-date
          cargo hakari manage-deps --dry-run # all workspace crates depend on workspace-hack
          cargo hakari verify
        '';

        nativeBuildInputs = [
          pkgs.cargo-hakari
        ];
      };
    };

    apps.default = {
      type = "app";
      program = "${self'.packages.default}/bin/${crateName}";
    };

    devShells.default = craneLibToolchain.devShell {
      # Inherit inputs from checks.
      checks = self'.checks;

      packages = [
        pkgs.cargo-hakari
        pkgs.cargo-nextest
        pkgs.rust-analyzer
      ];

      # Install the git hooks on shell entry (see modules/pre-commit.nix).
      shellHook = config.pre-commit.shellHook;
    };
  };
}
