import subprocess

from cookiecutter.main import cookiecutter


# Use a pytest fixture to create a temporary directory for each test
def test_project_creation_default_settings(tmp_path):
    """
    Tests that the project is generated with default settings and that its
    own tests pass.
    """
    # Generate the project in the temporary directory
    # 'no_input=True' uses the defaults from cookiecutter.json
    cookiecutter(
        template=".",
        output_dir=tmp_path,
        no_input=True,
    )

    project_path = tmp_path / "cookiecutter_rust_template"

    # --- Assertions for the generated project structure ---
    assert project_path.exists()
    assert project_path.is_dir()

    expected_files = [
        "README.md",
        "flake.nix",
        ".gitignore",
        "Cargo.toml",
        "src/main.rs",  # Package directory
    ]
    for file_path in expected_files:
        assert (project_path / file_path).exists()

    # --- Assertions for templated content ---
    readme_content = (project_path / "README.md").read_text()
    assert "# Cookiecutter Rust Template" in readme_content

    subprocess.run(
        ["nix", "flake", "check", "-L"],
        # The `check=True` argument will raise a CalledProcessError if the
        # command returns a non-zero exit code (i.e., if the tests fail).
        check=True,
        # Execute the command from within the generated project directory.
        cwd=project_path,
    )
