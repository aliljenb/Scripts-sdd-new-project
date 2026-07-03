# Requirements Document

## Introduction

A Bash script for macOS that scaffolds a new spec-driven development (SDD) project for Python. The workflow is Kiro-style (requirements → design → tasks) but is driven by the Claude CLI instead of Kiro: the generated project includes a `.claude/commands/` directory with slash commands that implement the SDD lifecycle. The script interactively prompts for a project name and Python module name, then generates the source layout, a matching test package, spec templates, Claude commands, a `pyproject.toml`, and a `.gitignore`, before initializing a local git repository with an initial commit.

## Glossary

- **Script**: The Bash shell script, named `new-sdd-project.sh`, that performs the scaffolding operation
- **Project_Root**: The top-level directory created by the Script, named after the user-provided project name
- **Python_Package**: A directory within `src/` containing an `__init__.py` file, named after the user-provided module name
- **Test_Package**: A `tests/` directory at the Project_Root level, containing an `__init__.py` file and a placeholder `test_<Python_Package>.py` file that imports pytest and is decorated with the `@pytest.mark.smoke` marker
- **Project_Manifest**: A `pyproject.toml` file at the Project_Root level that declares `pytest` as a development dependency and registers the `smoke` pytest marker
- **Spec_Templates**: Markdown template files (`requirements.md`, `design.md`, `tasks.md`) placed in the `specs/` directory following Kiro-style conventions
- **Claude_Commands**: Markdown files placed in `.claude/commands/` that define Claude CLI slash commands for the SDD lifecycle (`spec-requirements`, `spec-design`, `spec-tasks`, `implement-task`, `review`)

## Requirements

### Requirement 1: Interactive project configuration

**User Story:** As a developer, I want the script to prompt me for project configuration, so that the generated project matches my naming preferences.

#### Acceptance Criteria

1. WHEN the Script is executed, THE Script SHALL prompt the user for a project name via standard input
2. WHEN the Script is executed, THE Script SHALL prompt the user for a Python module name via standard input
3. WHEN the user provides a project name, THE Script SHALL use that value as the Project_Root directory name
4. WHEN the user provides a module name, THE Script SHALL use that value as the Python_Package directory name within `src/`

### Requirement 2: Input validation

**User Story:** As a developer, I want input validation, so that the script does not create malformed or conflicting project structures.

#### Acceptance Criteria

1. IF the user provides an empty project name, THEN THE Script SHALL display an error message and exit with a non-zero status code
2. IF the user provides an empty module name, THEN THE Script SHALL display an error message and exit with a non-zero status code
3. IF the user provides a module name that is not a valid Python identifier (does not match `^[a-zA-Z_][a-zA-Z0-9_]*$`), THEN THE Script SHALL display an error message and exit with a non-zero status code
4. IF a directory matching the Project_Root name already exists in the current working directory, THEN THE Script SHALL display an error message and exit with a non-zero status code
5. THE Script SHALL perform all validation before creating any files or directories

### Requirement 3: Python source layout

**User Story:** As a developer, I want the script to create a standard Python source layout with a matching unit test structure, so that my project follows best practices from the start and is ready for test-driven development.

#### Acceptance Criteria

1. WHEN the user provides valid inputs, THE Script SHALL create the Project_Root directory
2. WHEN the Project_Root is created, THE Script SHALL create a `src/` directory inside the Project_Root
3. WHEN the `src/` directory is created, THE Script SHALL create the Python_Package directory inside `src/`
4. WHEN the Python_Package directory is created, THE Script SHALL create an `__init__.py` file inside the Python_Package directory
5. WHEN the Project_Root is created, THE Script SHALL create a `tests/` directory inside the Project_Root, alongside `src/`
6. WHEN the `tests/` directory is created, THE Script SHALL create an `__init__.py` file inside the `tests/` directory, making it a Python package
7. WHEN the `tests/` directory is created, THE Script SHALL create a placeholder `test_<Python_Package>.py` file inside `tests/`, named using the Python_Package value, containing a minimal trivially-passing test function that uses the pytest library
8. WHEN the placeholder test function is created, THE Script SHALL include an `import pytest` statement in `test_<Python_Package>.py` and decorate the test function with a pytest marker (`@pytest.mark.smoke`)
9. WHEN the Project_Root is created, THE Script SHALL create a `pyproject.toml` file inside the Project_Root that declares `pytest` as a development dependency
10. WHEN `pyproject.toml` is created, THE Script SHALL register the `smoke` marker in `pyproject.toml` so that pytest does not emit an unknown-marker warning when the placeholder test runs

### Requirement 4: Kiro-style spec templates

**User Story:** As a developer, I want Kiro-style spec templates included in my project, so that I can immediately start documenting requirements, design, and tasks for features I build with Claude.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `specs/` directory inside the Project_Root
2. WHEN the `specs/` directory is created, THE Script SHALL create a `requirements.md` template file inside `specs/`
3. WHEN the `specs/` directory is created, THE Script SHALL create a `design.md` template file inside `specs/`
4. WHEN the `specs/` directory is created, THE Script SHALL create a `tasks.md` template file inside `specs/`
5. EACH Spec_Template SHALL contain a heading and a placeholder comment describing its purpose

### Requirement 5: Claude CLI SDD commands

**User Story:** As a developer, I want Claude CLI slash commands for the full SDD lifecycle, so that I can drive requirements, design, task breakdown, implementation, and review through Claude instead of Kiro.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `.claude/commands/` directory inside the Project_Root
2. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-requirements.md` command that instructs Claude to read and refine `specs/requirements.md`
3. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-design.md` command that instructs Claude to read `specs/requirements.md` and `specs/design.md` and refine the design
4. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-tasks.md` command that instructs Claude to read the specs and refine `specs/tasks.md`
5. WHEN the `.claude/commands/` directory is created, THE Script SHALL create an `implement-task.md` command that instructs Claude to implement the next unchecked task in `specs/tasks.md`
6. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `review.md` command that instructs Claude to review the implementation against the specs
7. WHEN the `spec-requirements.md` command is created, THE Script SHALL include in its content a `## Before writing or editing anything` section that instructs Claude to:
   - Stop and ask the user control questions before drafting or changing `requirements.md` whenever any part of the scope is unclear, ambiguous, or could reasonably be interpreted more than one way (including target users/roles, feature boundaries, edge cases, priority/must-have vs. nice-to-have, and measurable thresholds for acceptance criteria)
   - Ask one question at a time, or a small batch of tightly related questions
   - Offer 2-4 concrete, mutually exclusive multiple-choice options per question (in addition to a free-text "Other" option)
   - Use the `AskUserQuestion` tool so options are clickable, falling back to a lettered list (A/B/C/D) in chat only if that tool is unavailable
   - Withhold writing or editing `requirements.md` until blocking ambiguities are resolved, while stating minor non-blocking assumptions inline in the requirement text rather than asking about them

### Requirement 6: Git ignore rules

**User Story:** As a developer, I want a proper `.gitignore` file, so that common Python artifacts and macOS metadata files are excluded from version control.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `.gitignore` file inside the Project_Root
2. THE Script SHALL include common Python ignore patterns in the `.gitignore` file, including `__pycache__/`, `*.py[cod]`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, `.pytest_cache/`, and `.mypy_cache/`
3. THE Script SHALL include `.DS_Store` in the `.gitignore` file for macOS

### Requirement 7: macOS-native execution

**User Story:** As a developer, I want the script to run on macOS without additional dependencies, so that I can use it immediately on a standard macOS system.

#### Acceptance Criteria

1. THE Script SHALL use `/bin/bash` as the interpreter via a shebang line
2. THE Script SHALL use only commands available in a default macOS installation (`mkdir`, `cat`, `echo`, `read`)
3. THE Script SHALL be executable as a single file without requiring installation of additional tools
4. THE Script SHALL be named `new-sdd-project.sh`

### Requirement 8: Completion feedback

**User Story:** As a developer, I want confirmation of what was created, so that I know the scaffolding completed successfully.

#### Acceptance Criteria

1. WHEN all files and directories are created successfully, THE Script SHALL print a success message to standard output
2. WHEN all files and directories are created successfully, THE Script SHALL display the created directory structure to standard output, excluding the .git/ folder and its content.

### Requirement 9: Version control initialization

**User Story:** As a developer, I want the generated project committed to a fresh local git repository, so that I have a clean starting point for tracking changes from the very first file.

#### Acceptance Criteria

1. WHEN the file structure and content have been fully created, IF the `git` command is available, THEN THE Script SHALL initialize a git repository inside Project_Root
2. WHEN the git repository is initialized, THE Script SHALL stage all created files in the repository
3. WHEN all created files are staged, THE Script SHALL create a single commit with the message `Create initial project`
4. THE Script SHALL always run `git init` inside Project_Root, regardless of whether the current working directory is already inside another git repository
5. THE Script SHALL rely on the user's existing global git configuration (`user.name`/`user.email`) for the commit author identity and SHALL NOT set or override git identity configuration
6. IF the `git` command is not available on the system, THEN THE Script SHALL skip repository initialization and commit, display a warning message, and still exit with status code 0
7. IF `git init`, `git add`, or `git commit` fails for any reason (e.g. missing git identity configuration), THEN THE Script SHALL display a warning message and still exit with status code 0, since the file structure was already created successfully
