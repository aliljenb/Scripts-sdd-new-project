# Requirements Document

## Introduction

A Bash script for macOS that scaffolds a new spec-driven development (SDD) project for Python. The workflow is Kiro-style (requirements → design → tasks) but is driven by the Claude CLI instead of Kiro: the generated project includes a `.claude/commands/` directory with slash commands that implement the SDD lifecycle. The script interactively prompts for a project name and Python module name, then generates the source layout, spec templates, Claude commands, and a `.gitignore`.

## Glossary

- **Script**: The Bash shell script that performs the scaffolding operation
- **Project_Root**: The top-level directory created by the Script, named after the user-provided project name
- **Python_Package**: A directory within `src/` containing an `__init__.py` file, named after the user-provided module name
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

**User Story:** As a developer, I want the script to create a standard Python source layout, so that my project follows best practices from the start.

#### Acceptance Criteria

1. WHEN the user provides valid inputs, THE Script SHALL create the Project_Root directory
2. WHEN the Project_Root is created, THE Script SHALL create a `src/` directory inside the Project_Root
3. WHEN the `src/` directory is created, THE Script SHALL create the Python_Package directory inside `src/`
4. WHEN the Python_Package directory is created, THE Script SHALL create an `__init__.py` file inside the Python_Package directory

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

### Requirement 8: Completion feedback

**User Story:** As a developer, I want confirmation of what was created, so that I know the scaffolding completed successfully.

#### Acceptance Criteria

1. WHEN all files and directories are created successfully, THE Script SHALL print a success message to standard output
2. WHEN all files and directories are created successfully, THE Script SHALL display the created directory structure to standard output
