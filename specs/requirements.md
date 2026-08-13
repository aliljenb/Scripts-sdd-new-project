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
- **Suggested_Module_Name**: A valid Python identifier computed by the Script from the user-provided project name, offered as the pre-filled default value at the Python module name prompt (see Requirement 11)

## Requirements

### Requirement 1: Interactive project configuration

**User Story:** As a developer, I want the script to prompt me for project configuration, so that the generated project matches my naming preferences.

#### Acceptance Criteria

1. WHEN the Script is executed, THE Script SHALL prompt the user for a project name via standard input
2. WHEN the project name has been prompted for and validated, THE Script SHALL prompt the user for a Python module name via standard input, displaying the Suggested_Module_Name (Requirement 11) as the pre-filled default in that prompt
3. WHEN the user provides a project name, THE Script SHALL use that value as the Project_Root directory name
4. WHEN the user submits a non-empty value at the Python module name prompt, THE Script SHALL use that typed value as the Python_Package directory name within `src/`, in place of the Suggested_Module_Name

### Requirement 2: Input validation

**User Story:** As a developer, I want input validation, so that the script does not create malformed or conflicting project structures.

#### Acceptance Criteria

1. IF the user provides an empty project name, THEN THE Script SHALL display an error message and exit with a non-zero status code
2. IF the user submits empty input (presses Enter without typing a value) at the Python module name prompt, THEN THE Script SHALL treat this as acceptance of the Suggested_Module_Name (Requirement 11) rather than as an error, since a valid non-empty suggestion is always available by that point in the prompt flow
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
6. WHEN the `design.md` template is created, THE Script SHALL include in its content a design note stating that all Python code, except test files, SHALL reside inside the Python_Package directory under `src/`, so that every project scaffolded by the Script starts with this source-layout constraint already documented for its own future development

### Requirement 5: Claude CLI SDD commands

**User Story:** As a developer, I want Claude CLI slash commands for the full SDD lifecycle, so that I can drive requirements, design, task breakdown, implementation, and review through Claude instead of Kiro.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `.claude/commands/` directory inside the Project_Root
2. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-requirements.md` command that instructs Claude to read and refine `specs/requirements.md`
3. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-design.md` command that instructs Claude to read `specs/requirements.md` and `specs/design.md` and refine the design
4. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `spec-tasks.md` command that instructs Claude to read the specs and refine `specs/tasks.md`
5. WHEN the `.claude/commands/` directory is created, THE Script SHALL create an `implement-task.md` command that instructs Claude to implement the next unchecked task in `specs/tasks.md`
6. IF more than one unchecked task (`- [ ]`) remains in `specs/tasks.md` WHEN the `implement-task.md` command is invoked, THEN THE command SHALL instruct Claude to ask the user whether to implement all remaining unchecked tasks at once or one at a time, before implementing any task
7. IF exactly one unchecked task remains in `specs/tasks.md` WHEN the `implement-task.md` command is invoked, THEN THE command SHALL instruct Claude to implement that task directly without asking the all-at-once-vs-one-by-one question
8. IF the user chooses to implement all remaining tasks at once, AND an error or test failure occurs while implementing one of the tasks, THEN THE command SHALL instruct Claude to stop the loop immediately, leave that task and all subsequent tasks unchecked, and report the failure to the user, rather than continuing to later tasks
9. WHEN the `.claude/commands/` directory is created, THE Script SHALL create a `review.md` command that instructs Claude to review the implementation against the specs
10. WHEN the `spec-requirements.md` command is created, THE Script SHALL include in its content a `## Before writing or editing anything` section that instructs Claude to:
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

### Requirement 10: Development discipline guidance in CLAUDE.md

**User Story:** As a developer, I want the generated project to include a `CLAUDE.md` file with development discipline guidance, so that Claude Code sessions working in the generated project make scoped, reviewable changes and don't act on stale or unapproved work.

#### Acceptance Criteria

1. WHEN the Project_Root is created, THE Script SHALL create a `CLAUDE.md` file inside the `.claude/` directory (i.e. `.claude/CLAUDE.md`)
2. THE `.claude/CLAUDE.md` file SHALL contain a `## Development discipline` heading
3. THE `.claude/CLAUDE.md` file SHALL instruct that code SHALL NOT be modified unless explicitly asked to implement or change something
4. THE `.claude/CLAUDE.md` file SHALL instruct that, for investigation/review tasks, the existing implementation SHALL be inspected first and work SHALL stop for review before making changes
5. THE `.claude/CLAUDE.md` file SHALL instruct that changes SHALL NOT be committed or pushed unless explicitly instructed
6. THE `.claude/CLAUDE.md` file SHALL instruct that unrelated working-tree changes SHALL be preserved
7. THE `.claude/CLAUDE.md` file SHALL instruct that existing user changes SHALL NOT be reverted unless explicitly instructed
8. THE `.claude/CLAUDE.md` file SHALL instruct that implementation scope SHALL be kept aligned with the approved task
9. THE `.claude/CLAUDE.md` file SHALL instruct that missing behavior or architectural abstractions SHALL NOT be invented before inspecting the existing code
10. THE `.claude/CLAUDE.md` file SHALL instruct that, when a proposed change has not been verified, it SHALL be clearly distinguished from verified behavior
11. THE `.claude/CLAUDE.md` file SHALL instruct a preference for small, incremental changes with explicit verification
12. THE `.claude/CLAUDE.md` file SHALL instruct that unrelated work SHALL NOT be started because of stale, duplicated, or automatically generated task prompts
13. THE content of `.claude/CLAUDE.md` SHALL be static (no variable substitution) and identical across every project generated by the Script

### Requirement 11: Suggested Python module name from the project name

**User Story:** As a developer, I want the script to suggest a valid Python module name based on the project name I entered, so that I don't have to manually retype and reformat the module name by hand when it can be derived automatically.

#### Acceptance Criteria

1. AFTER the project name has been prompted for and has passed validation (Requirement 2.1), THE Script SHALL compute a Suggested_Module_Name by sanitizing the project name into a valid Python identifier, before prompting for the module name
2. THE sanitization in Criterion 1 SHALL, in order:
   a. Insert an underscore at camelCase word boundaries — before an uppercase letter that is preceded by a lowercase letter or digit, and before the final uppercase letter of a run of two or more consecutive uppercase letters when that letter is followed by a lowercase letter, so that acronym runs are treated as a single segment (e.g. `HTTPServer` → `HTTP_Server`)
   b. Replace every character that is not a letter, digit, or underscore with an underscore
   c. Collapse runs of two or more consecutive underscores into a single underscore
   d. Convert the entire string to lowercase
   e. Strip any leading or trailing underscore produced by steps (a)–(c), except that a single leading underscore already present in the original project name SHALL be preserved
3. IF the sanitized result from Criterion 2 begins with a digit, THEN THE Script SHALL prepend a single underscore to it (e.g. project name `123` → Suggested_Module_Name `_123`)
4. IF the sanitized result from Criterion 2 is an empty string, THEN THE Script SHALL use the fixed fallback value `_module` as the Suggested_Module_Name
5. THE Script SHALL display the Suggested_Module_Name to the user as the pre-filled default in the Python module name prompt (e.g. `Enter Python module name [basic_test]:`)
6. THE resolved module name value — whether the accepted Suggested_Module_Name or a typed override (Requirement 1.4) — SHALL still be subject to the existing Python-identifier validation (Requirement 2.3)
7. THE Suggested_Module_Name computation SHALL be deterministic: for a given project name it SHALL always produce the same Suggested_Module_Name

##### Examples

| Project name | Suggested_Module_Name |
|---|---|
| `BasicTest` | `basic_test` |
| `basic-test` | `basic_test` |
| `basic_test` | `basic_test` |
| `HTTPServer` | `http_server` |
| `MyIOTool` | `my_io_tool` |
| `123` | `_123` |
| `...` | `_module` |
| `_9lives` | `_9lives` |
