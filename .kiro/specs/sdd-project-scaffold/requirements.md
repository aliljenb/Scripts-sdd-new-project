# Requirements Document

## Introduction

A Bash script for macOS that scaffolds a new spec-driven development (SDD) project structure for Python. The script interactively prompts the user for configuration details and generates a complete project directory with source code layout, test infrastructure, specification templates, and Claude slash commands for the SDD lifecycle.

## Glossary

- **Script**: The Bash shell script that performs the scaffolding operation
- **Project_Root**: The top-level directory created by the Script, named after the user-provided project name
- **Python_Package**: A directory within `src/` containing an `__init__.py` file, named after the user-provided module name
- **Spec_Templates**: Markdown template files (`requirements.md`, `design.md`, `tasks.md`) placed in the `specs/` directory following Kiro-style conventions
- **Slash_Commands**: Markdown files placed in `.claude/commands/` that define Claude Code slash commands for the SDD lifecycle
- **Test_Infrastructure**: The pytest-based testing setup including `pyproject.toml` configuration, `tests/` directory, and `conftest.py`

## Requirements

### Requirement 1

**User Story:** As a developer, I want the script to prompt me for project configuration, so that the generated project matches my naming preferences.

#### Acceptance Criteria

1. WHEN the Script is executed, THE Script SHALL prompt the user for a project name via standard input
2. WHEN the Script is executed, THE Script SHALL prompt the user for a Python module name via standard input
3. WHEN the user provides a project name, THE Script SHALL use that value as the Project_Root directory name
4. WHEN the user provides a module name, THE Script SHALL use that value as the Python_Package directory name within `src/`

### Requirement 2

**User Story:** As a developer, I want the script to create a standard Python source layout, so that my project follows best practices from the start.

#### Acceptance Criteria

1. WHEN the user provides valid inputs, THE Script SHALL create the Project_Root directory
2. WHEN the Project_Root is created, THE Script SHALL create a `src/` directory inside the Project_Root
3. WHEN the `src/` directory is created, THE Script SHALL create the Python_Package directory inside `src/`
4. WHEN the Python_Package directory is created, THE Script SHALL create an `__init__.py` file inside the Python_Package directory

### Requirement 3

**User Story:** As a developer, I want spec templates included in my project, so that I can immediately start documenting requirements, design, and tasks.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `specs/` directory inside the Project_Root
2. WHEN the `specs/` directory is created, THE Script SHALL create a `requirements.md` template file inside `specs/`
3. WHEN the `specs/` directory is created, THE Script SHALL create a `design.md` template file inside `specs/`
4. WHEN the `specs/` directory is created, THE Script SHALL create a `tasks.md` template file inside `specs/`

### Requirement 4

**User Story:** As a developer, I want Claude slash commands for the full SDD lifecycle, so that I can drive spec-driven development through Claude Code.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `.claude/commands/` directory inside the Project_Root
2. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-requirements.md` slash command file
3. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-design.md` slash command file
4. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-tasks.md` slash command file
5. WHEN the `.claude/commands/` directory is created, THE Script SHALL create an `implement-task.md` slash command file
6. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `review.md` slash command file

### Requirement 5

**User Story:** As a developer, I want a proper `.gitignore` file, so that common Python artifacts and macOS metadata files are excluded from version control.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `.gitignore` file inside the Project_Root
2. THE Script SHALL include Python-specific ignore patterns in the `.gitignore` file (including `__pycache__/`, `*.pyc`, `*.pyo`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`)
3. THE Script SHALL include `.DS_Store` in the `.gitignore` file

### Requirement 6

**User Story:** As a developer, I want pytest infrastructure set up, so that I can write and run tests immediately.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `pyproject.toml` file inside the Project_Root with pytest configuration
2. WHEN the Project_Root is created, THE Script SHALL create a `tests/` directory inside the Project_Root
3. WHEN the `tests/` directory is created, THE Script SHALL create a `conftest.py` file inside the `tests/` directory
4. THE Script SHALL configure `pyproject.toml` with the project name and a `[tool.pytest.ini_options]` section

### Requirement 7

**User Story:** As a developer, I want the script to run on macOS without additional dependencies, so that I can use it immediately on a standard macOS system.

#### Acceptance Criteria

1. THE Script SHALL use `/bin/bash` as the interpreter via a shebang line
2. THE Script SHALL use only commands available in a default macOS installation (mkdir, cat, echo, read)
3. THE Script SHALL be executable as a single file without requiring installation of additional tools

### Requirement 8

**User Story:** As a developer, I want confirmation of what was created, so that I know the scaffolding completed successfully.

#### Acceptance Criteria

1. WHEN all files and directories are created successfully, THE Script SHALL print a success message to standard output
2. WHEN all files and directories are created successfully, THE Script SHALL display the created directory structure to standard output

### Requirement 9

**User Story:** As a developer, I want input validation, so that the script does not create malformed project structures.

#### Acceptance Criteria

1. IF the user provides an empty project name, THEN THE Script SHALL display an error message and exit with a non-zero status code
2. IF the user provides an empty module name, THEN THE Script SHALL display an error message and exit with a non-zero status code
3. IF the user provides a non-standard Python module name, THEN THE Script SHALL display an error message and exit with a non-zero status code
4. IF the Project_Root directory already exists, THEN THE Script SHALL display an error message and exit with a non-zero status code

### Requirement 10

**User Story:** As a developer, I want the script to initialize a git repository and after all is created, also perform an initial commit.

#### Acceptance Criteria

1. WHEN all files and directories are created successfully, THE Script SHALL initialize a local git repository
2. WHEN all files and directories are created successfully, THE Script SHALL commit with the message "Initial creation"
