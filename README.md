# Java Project Scaffolder

A command-line tool for generating new Java projects from predefined templates. This tool is built with [Bashly](https://bashly.dannyb.co/) to provide a clean and maintainable CLI interface.

## Quick Install

You can install the `scaffold` tool with a single command. This does not require `sudo`.

```bash
curl -fsSL https://raw.githubusercontent.com/taminhtienhai/scaffold/main/install.sh | sh -s -- -i
```

This will download and install the script to `$HOME/.local/bin/scaffold`.

The installer will notify you if you need to add this directory to your `PATH`.

## Features

- **Template-Based Generation**: Create projects from either local directories or remote Git repositories.
- **Configuration via `scaffold.ini`**: Templates can include a `scaffold.ini` file to define default project metadata.
- **Dynamic Placeholder Replacement**: Replaces placeholders like `${GROUP_ID}`, `${ID}`, `${DESCRIPTION}`, and `${AUTHOR}` throughout the template files.
- **Java Package Structure**: Automatically creates the standard Java package directory structure (`src/main/java/...`, `src/test/java/...`) based on the provided Group ID and Artifact ID.
- **Pre/Post Hooks**: Execute custom scripts before and after the scaffolding process.
- **Interactive Prompts**: Asks for required information (like Group ID and Artifact ID) if not provided via command-line arguments.
- **Input Validation**: Ensures that required arguments are provided and that output directories are handled safely.
- **Colored Logging**: Provides clear, color-coded feedback for information, warnings, and errors.
- **Debug & Verbose Modes**: Offers `--debug` and `--verbose` flags for more detailed output.

## Dependencies

The following tools must be installed on your system:
- `git`: For cloning remote templates.
- `rsync`: For copying local templates.

You can check for these dependencies by running:
```bash
scaffold --deps
```

## Installation from Source

1.  **Install Bashly**:
    ```bash
    gem install bashly
    ```
2.  **Generate the Script**:
    ```bash
    bashly generate
    ```
3.  **Make it Executable**:
    ```bash
    chmod +x scaffold
    ```

## Usage

The script can be run with various options to customize the project generation.

### Basic Examples

**Generate from a local template:**
```bash
scaffold --path ~/templates/my-java-template --out ./my-new-project
```

**Generate from a remote Git template:**
```bash
scaffold --git https://github.com/user/java-template.git --out ./my-new-project
```

**Override `scaffold.ini` values:**
```bash
scaffold --path ~/templates/my-java-template --group-id com.mycompany --artifact-id my-app
```

### Command-Line Flags

| Flag | Short | Argument | Description |
|---|---|---|---|
| `--help` | `-h` | | Show the help message. |
| `--deps` | | | Show the list of required CLI tool dependencies. |
| `--debug` | `-d` | | Enable debug mode for detailed logs. |
| `--verbose` | `-V` | | Enable verbose output. |
| `--force` | `-f` | | Force overwrite of an existing output directory. |
| `--path` | `-p` | `path` | Path to the local template directory. |
| `--git` | `-g` | `git_repo` | URL of the remote Git repository template. |
| `--group-id`| | `group_id` | The `groupId` for the Java project (e.g., `com.example.app`). |
| `--artifact-id`| | `artifact_id`| The `artifactId` for the Java project (e.g., `my-app`). |
| `--out` | `-o` | `dir` | The output directory for the generated project (default: `.`). |

## Template Configuration (`scaffold.ini`)

Your template directory can contain a `scaffold.ini` file to provide default values for the project.

```ini
# Example scaffold.ini
ID=my-default-app
GROUP_ID=com.example.default
DESCRIPTION=A default description for my awesome app.
AUTHOR=Jane Doe
PRE_HOOK=./scripts/setup.sh
POST_HOOK=./scripts/cleanup.sh
```

- **ID**: The default `artifactId`.
- **GROUP_ID**: The default `groupId`.
- **DESCRIPTION**: A description of the project.
- **AUTHOR**: The author's name.
- **PRE_HOOK**: A command to run before scaffolding.
- **POST_HOOK**: A command to run after scaffolding.

## Development

To modify this tool:
1.  Edit the `src/bashly.yml` file to change CLI commands, flags, or arguments.
2.  Edit the shell scripts in `src/lib/` to modify the core logic.
3.  Run `bashly generate` to rebuild the `scaffold` script with your changes.
4.  Run `scaffold` to test your modifications.
