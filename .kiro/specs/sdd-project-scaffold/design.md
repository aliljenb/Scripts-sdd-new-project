# Design Document

## Overview

The SDD Project Scaffold script is a single-file Bash script that generates a complete spec-driven development project structure for Python. It follows a linear pipeline architecture: prompt for input → validate → create directory structure → write file contents → initialize git → report results.

## Architecture

### Pipeline Stages

The script executes as a sequential pipeline with early-exit on failure:

```
┌─────────┐    ┌──────────┐    ┌─────────────┐    ┌───────────────┐    ┌──────────┐    ┌────────┐
│  Prompt  │───▶│ Validate │───▶│ Create Dirs │───▶│ Write Files   │───▶│ Git Init │───▶│ Report │
└─────────┘    └──────────┘    └─────────────┘    └───────────────┘    └──────────┘    └────────┘
                    │                                                                        │
                    ▼                                                                        ▼
              Exit non-zero                                                           Exit 0 + tree
```

1. **Prompt Stage** — Read project name and module name from stdin via `read`
2. **Validate Stage** — Reject empty inputs, invalid Python identifiers, and pre-existing directories
3. **Create Dirs Stage** — Create the full directory tree using `mkdir -p`
4. **Write Files Stage** — Write all template files using heredocs/`cat`
5. **Git Init Stage** — Initialize a git repository and perform the initial commit
6. **Report Stage** — Print success message and directory structure

### Error Handling

Each validation check triggers immediate exit with a non-zero status code and an error message to stdout. The script does not attempt partial cleanup on failure — validation runs before any filesystem changes.

## Components

### 1. Input Prompting

```bash
#!/bin/bash

echo "Enter project name:"
read -r PROJECT_NAME

echo "Enter Python module name:"
read -r MODULE_NAME
```

Uses `read -r` to prevent backslash interpretation. Prompts go to stdout so they are visible in interactive use.

### 2. Input Validation

```bash
# Empty project name check
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

# Empty module name check
if [ -z "$MODULE_NAME" ]; then
    echo "Error: Module name cannot be empty."
    exit 1
fi

# Python identifier validation (letters/underscores, no leading digit, no hyphens/spaces)
if ! [[ "$MODULE_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Error: Module name must be a valid Python identifier."
    exit 1
fi

# Pre-existing directory check
if [ -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' already exists."
    exit 1
fi
```

Validation rules:
- Project name: must be non-empty
- Module name: must be non-empty and match `^[a-zA-Z_][a-zA-Z0-9_]*$` (valid Python identifier)
- Project directory: must not already exist in the current working directory

### 3. Directory Creation

```bash
mkdir -p "$PROJECT_NAME/src/$MODULE_NAME"
mkdir -p "$PROJECT_NAME/specs"
mkdir -p "$PROJECT_NAME/tests"
mkdir -p "$PROJECT_NAME/.claude/commands"
```

Uses `mkdir -p` to create the full tree in minimal calls. The directories created:

```
{PROJECT_NAME}/
├── src/{MODULE_NAME}/
├── specs/
├── tests/
└── .claude/commands/
```

### 4. File Generation

All files are written using `cat` with heredocs. The content is deterministic given the inputs.

#### Files Created

| Path | Content Summary |
|------|----------------|
| `src/{MODULE_NAME}/__init__.py` | Empty file (Python package marker) |
| `specs/requirements.md` | Markdown template with heading and placeholder |
| `specs/design.md` | Markdown template with heading and placeholder |
| `specs/tasks.md` | Markdown template with heading and placeholder |
| `.claude/commands/spec-requirements.md` | Slash command for requirements generation |
| `.claude/commands/spec-design.md` | Slash command for design generation |
| `.claude/commands/spec-tasks.md` | Slash command for task breakdown |
| `.claude/commands/implement-task.md` | Slash command for task implementation |
| `.claude/commands/review.md` | Slash command for code review |
| `.gitignore` | Python + macOS ignore patterns |
| `pyproject.toml` | Project metadata + pytest configuration |
| `tests/conftest.py` | Empty conftest for pytest fixtures |

#### .gitignore Content

```
__pycache__/
*.pyc
*.pyo
.eggs/
*.egg-info/
dist/
build/
.venv/
venv/
.DS_Store
```

#### pyproject.toml Structure

```toml
[project]
name = "{PROJECT_NAME}"
version = "0.1.0"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

The `{PROJECT_NAME}` placeholder is substituted with the user-provided project name at generation time.

### 5. Git Initialization

```bash
cd "$PROJECT_NAME"
git init
git add -A
git commit -m "Initial creation"
cd ..
```

After all files and directories are created, the script:
1. Changes into the Project_Root directory
2. Initializes a new git repository with `git init`
3. Stages all generated files with `git add -A`
4. Creates an initial commit with the message `"Initial creation"`
5. Returns to the original directory

This stage runs after the Report stage would logically occur, but before the script exits. The ordering ensures all files exist before committing.

### 6. Success Reporting

```bash
echo ""
echo "Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Directory structure:"
# Display tree using find or manual echo
```

The directory structure display uses commands available on default macOS (`find` with formatting, or manual `echo` statements listing each path).

## Data Flow

```
User Input ──▶ Variables (PROJECT_NAME, MODULE_NAME)
                    │
                    ▼
             Validation Gates (exit 1 on failure)
                    │
                    ▼
             Filesystem Operations (mkdir, cat)
                    │
                    ▼
             Git Operations (git init, git add, git commit)
                    │
                    ▼
             stdout (success message + tree)
```

## Interface

### Inputs
- **stdin**: Project name (line 1), Module name (line 2)

### Outputs
- **stdout**: Prompts, success message, directory tree (on success); error messages (on failure)
- **Exit code**: 0 on success, non-zero on validation failure
- **Filesystem**: Complete project directory tree at `./{PROJECT_NAME}/`

### Usage

```bash
# Interactive
./scaffold.sh

# Piped (for testing)
echo -e "my-project\nmy_module" | ./scaffold.sh
```

## Constraints

- Uses only `/bin/bash` and default macOS commands: `echo`, `read`, `mkdir`, `cat`, `git`, `find`/`ls`
- Single-file script, no external dependencies beyond git (which is standard on macOS with Xcode CLI tools)
- No network access required
- All file content is static templates (no dynamic fetching)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Input-to-directory-name fidelity

*For any* valid project name and valid module name provided as input, the script SHALL create a directory named exactly as the project name, containing `src/{module_name}/` as a subdirectory.

**Validates: Requirements 1.3, 1.4, 2.1, 2.2, 2.3**

### Property 2: Complete directory structure invariant

*For any* valid input pair (project name, module name), the script SHALL create all required directories and files: `src/{module_name}/__init__.py`, `specs/requirements.md`, `specs/design.md`, `specs/tasks.md`, `.claude/commands/spec-requirements.md`, `.claude/commands/spec-design.md`, `.claude/commands/spec-tasks.md`, `.claude/commands/implement-task.md`, `.claude/commands/review.md`, `.gitignore`, `pyproject.toml`, `tests/conftest.py`.

**Validates: Requirements 2.4, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 6.1, 6.2, 6.3**

### Property 3: .gitignore content completeness

*For any* valid input pair, the generated `.gitignore` file SHALL contain all required patterns: `__pycache__/`, `*.pyc`, `*.pyo`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, and `.DS_Store`.

**Validates: Requirements 5.2, 5.3**

### Property 4: pyproject.toml reflects project name

*For any* valid project name, the generated `pyproject.toml` SHALL contain the user-provided project name in the `[project]` section and include a `[tool.pytest.ini_options]` section.

**Validates: Requirements 6.4**

### Property 5: Invalid module name rejection

*For any* string that does not match the pattern `^[a-zA-Z_][a-zA-Z0-9_]*$`, the script SHALL exit with a non-zero status code and no project directory shall be created.

**Validates: Requirements 9.3**

### Property 6: Git repository initialization

*For any* valid input pair, after the script completes, the Project_Root SHALL contain a `.git/` directory (indicating an initialized repository) and `git log` within that directory SHALL show at least one commit with the message "Initial creation".

**Validates: Requirements 10.1, 10.2**

### Property 7: Success output contains structure

*For any* valid input pair, the script's stdout SHALL contain a success message and references to the created directory paths.

**Validates: Requirements 8.1, 8.2**
