import re
import subprocess

import pytest
from cookiecutter.main import cookiecutter

PROJECT_SLUG = "cookiecutter_rust_template"


@pytest.fixture
def project_path(tmp_path):
    """Render the template with default settings into a temp directory."""
    cookiecutter(template=".", output_dir=tmp_path, no_input=True)
    path = tmp_path / PROJECT_SLUG
    assert path.is_dir()
    return path


def test_project_structure_default_settings(project_path):
    """The generated workspace has the expected loop-stack layout."""
    expected_files = [
        "README.md",
        "flake.nix",
        ".gitignore",
        "Cargo.toml",
        "clippy.toml",
        "crates/cookiecutter_rust_template/src/main.rs",
        "crates/cookiecutter_rust_template/Cargo.toml",
        "crates/workspace-hack/Cargo.toml",
        "crates/workspace-hack/src/lib.rs",
        "crates/workspace-hack/build.rs",
        "crates/workspace-hack/.gitattributes",
        ".config/hakari.toml",
        "nix/modules/default.nix",
        "nix/modules/fmt.nix",
        "nix/modules/pre-commit.nix",
        "nix/modules/rust.nix",
    ]
    for file_path in expected_files:
        assert (project_path / file_path).exists(), f"missing: {file_path}"


def test_workspace_manifest_wiring(project_path):
    """Workspace lints must actually apply (P1 regression guard)."""
    root = (project_path / "Cargo.toml").read_text()
    crate = (project_path / f"crates/{PROJECT_SLUG}/Cargo.toml").read_text()

    assert 'members = ["crates/*"]' in root
    assert "[workspace.lints.clippy]" in root
    assert "unwrap_used" in root  # lints really shipped
    # The post-gen `nix fmt` (taplo) may normalize the dotted key into a
    # `[lints]` table — accept both equivalent spellings.
    assert re.search(
        r"(\[lints\]\s*workspace\s*=\s*true|lints\.workspace\s*=\s*true)", crate
    )
    assert 'workspace-hack = { version = "0.1", path = "../workspace-hack" }' in crate


def test_templated_content(project_path):
    readme = (project_path / "README.md").read_text()
    assert "# Cookiecutter Rust Template" in readme
    assert "loop stack" in readme


def test_project_flake_check(project_path):
    """Full gate: the generated project must build and pass all checks."""
    subprocess.run(
        ["nix", "flake", "check", "-L"],
        check=True,
        cwd=project_path,
    )
