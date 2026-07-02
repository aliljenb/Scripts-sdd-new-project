# Design Document

## Overview

The SDD Project Scaffold script is a single-file Bash script that generates a complete spec-driven development project structure for Python, driven by the Claude CLI. It follows a linear pipeline architecture: prompt for input → validate → create directory structure → write file contents → report results.

## Architecture

### Pipeline Stages

The script executes as a sequential pipeline with early-exit on failure:

```
┌─────────┐    ┌──────────┐    ┌─────────────┐    ┌───────────────┐    ┌────────┐
│  Prompt  │───▶│ Validate │───▶│ Create Dirs │───▶│ Write Files   │───▶│ Report │
└─────────┘    └──────────┘    └─────────────┘    └───────────────┘    └────────┘
                    │                                                        │
                    ▼                                                        ▼
              Exit non-zero                                            Exit 0 + tree
```

1. **Prompt Stage** — Read project name and module name from stdin via `read`
2. **Validate Stage** — Reject empty inputs, invalid Python identifiers, and pre-existing directories
3. **Create Dirs Stage** — Create the full directory tree using `mkdir -p`
4. **Write Files Stage** — Write all template files using heredocs/`cat`
5. **Report Stage** — Print success message and directory structure

### Error Handling

Each validation check triggers immediate exit with a non-zero status code and an error message to stdout. The script does not attempt partial cleanup on failure — validation runs before any filesystem changes, so a failed run never leaves a partially created project on disk.

## Components

### 1. Input Prompting

```bash
#!/bin/bash

echo "Enter project name:"
read -r PROJECT_NAME

echo "Enter Python module name:"
read -r MODULE_NAME
```

Uses `read -r` to prevent backslash interpretation. Prompts go to stdout so they are visible in interactive use, and the script also works when input is piped (e.g. `echo -e "name\nmodule" | ./new-sdd-project.sh`) for scripted/test invocation.

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

All checks run before any `mkdir`/`cat` call, so validation failures never touch the filesystem.

### 3. Directory Creation

```bash
mkdir -p "$PROJECT_NAME/src/$MODULE_NAME"
mkdir -p "$PROJECT_NAME/specs"
mkdir -p "$PROJECT_NAME/.claude/commands"
```

Uses `mkdir -p` to create the full tree in minimal calls. The directories created:

```
{PROJECT_NAME}/
├── src/{MODULE_NAME}/
├── specs/
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

#### .gitignore Content

```
__pycache__/
*.py[cod]
.eggs/
*.egg-info/
dist/
build/
.venv/
venv/
.pytest_cache/
.mypy_cache/
.DS_Store
```

#### Claude Command Content

Each file in `.claude/commands/` is a plain-text prompt body (no special frontmatter required) that instructs Claude, when the corresponding slash command is invoked, to read the relevant `specs/*.md` files and update them:

- `spec-requirements.md` → read/refine `specs/requirements.md` (user stories + acceptance criteria)
- `spec-design.md` → read `specs/requirements.md` + `specs/design.md`, refine the design
- `spec-tasks.md` → read all three specs, refine `specs/tasks.md`
- `implement-task.md` → read `specs/tasks.md` + `specs/design.md`, implement the next unchecked task
- `review.md` → read all specs and the source tree, review the implementation against them

### 5. Success Reporting

```bash
echo ""
echo "Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Directory structure:"
find "$PROJECT_NAME" -print | sed -e "s;[^/]*/;  ;g;s;  \([^ ]\);├─ \1;"
```

The directory structure display uses commands available on default macOS (`find`, `sed`) to render a tree without requiring the `tree` package.

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
./new-sdd-project.sh

# Piped (for testing)
echo -e "my-project\nmy_module" | ./new-sdd-project.sh
```

## Design Decisions & Trade-offs

- **Single-file script vs. multiple sourced files**: A single file was chosen for portability — the script can be copied and run without preserving a directory structure. The trade-off is a longer file, mitigated by clear stage comments.
- **Static heredoc templates vs. templating engine**: Content is generated with plain `cat <<'EOF'` heredocs rather than a templating tool (e.g. `envsubst`), since the only substitution needed is the project name in a couple of places, and heredocs keep the script dependency-free.
- **Validate-before-create vs. create-then-rollback**: All validation happens before any directory or file is created, avoiding the need for cleanup/rollback logic on failure. This is simpler and safer than partial writes with a rollback path.
- **No git initialization**: Unlike the earlier Kiro-based draft of this script, this version does not run `git init`/`git commit`. Scaffolding stays a pure filesystem operation; the user decides when and how to initialize version control.
- **No pytest scaffolding**: Test infrastructure (`pyproject.toml`, `tests/`) is intentionally out of scope for this iteration per the current requirements — the script focuses on the SDD spec/command layout and the minimal Python package skeleton.

## Constraints

- Uses only `/bin/bash` and default macOS commands: `echo`, `read`, `mkdir`, `cat`, `find`, `sed`
- Single-file script, no external dependencies
- No network access required
- All file content is static templates (no dynamic fetching)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Input-to-directory-name fidelity

*For any* valid project name and valid module name provided as input, the script SHALL create a directory named exactly as the project name, containing `src/{module_name}/` as a subdirectory.

**Validates: Requirements 1.3, 1.4, 3.1, 3.2, 3.3**

### Property 2: Complete directory structure invariant

*For any* valid input pair (project name, module name), the script SHALL create all required directories and files: `src/{module_name}/__init__.py`, `specs/requirements.md`, `specs/design.md`, `specs/tasks.md`, `.claude/commands/spec-requirements.md`, `.claude/commands/spec-design.md`, `.claude/commands/spec-tasks.md`, `.claude/commands/implement-task.md`, `.claude/commands/review.md`, `.gitignore`.

**Validates: Requirements 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.1**

### Property 3: .gitignore content completeness

*For any* valid input pair, the generated `.gitignore` file SHALL contain all required patterns: `__pycache__/`, `*.py[cod]`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, `.pytest_cache/`, `.mypy_cache/`, and `.DS_Store`.

**Validates: Requirements 6.2, 6.3**

### Property 4: Invalid module name rejection

*For any* string that does not match the pattern `^[a-zA-Z_][a-zA-Z0-9_]*$`, the script SHALL exit with a non-zero status code and no project directory shall be created.

**Validates: Requirements 2.3, 2.5**

### Property 5: Empty input rejection

*For any* invocation where the project name or module name is empty, the script SHALL exit with a non-zero status code and no project directory shall be created.

**Validates: Requirements 2.1, 2.2, 2.5**

### Property 6: Pre-existing directory rejection

*For any* project name that already exists as a directory in the current working directory, the script SHALL exit with a non-zero status code without modifying the existing directory.

**Validates: Requirement 2.4**

### Property 7: Success output contains structure

*For any* valid input pair, the script's stdout SHALL contain a success message and references to the created directory paths.

**Validates: Requirements 8.1, 8.2**
