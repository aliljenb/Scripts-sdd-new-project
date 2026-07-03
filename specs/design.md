# Design Document

## Overview

The SDD Project Scaffold script is a single-file Bash script that generates a complete spec-driven development project structure for Python, driven by the Claude CLI. It follows a linear pipeline architecture: prompt for input → validate → create directory structure → write file contents → initialize git → report results.

## Architecture

### Pipeline Stages

The script executes as a sequential pipeline with early-exit on validation failure. The Git Init stage is best-effort and never causes a non-zero exit:

```
┌─────────┐  ┌──────────┐  ┌─────────────┐  ┌───────────────┐  ┌──────────┐  ┌────────┐
│  Prompt  │─▶│ Validate │─▶│ Create Dirs │─▶│ Write Files   │─▶│ Git Init │─▶│ Report │
└─────────┘  └──────────┘  └─────────────┘  └───────────────┘  └──────────┘  └────────┘
                  │                                                  │             │
                  ▼                                                  ▼             ▼
            Exit non-zero                                   Warn on failure   Exit 0 + tree
                                                              (never exits non-zero)
```

1. **Prompt Stage** — Read project name and module name from stdin via `read`
2. **Validate Stage** — Reject empty inputs, invalid Python identifiers, and pre-existing directories
3. **Create Dirs Stage** — Create the full directory tree using `mkdir -p`
4. **Write Files Stage** — Write all template files using heredocs/`cat`
5. **Git Init Stage** — Initialize a git repository inside Project_Root and create the initial commit, best-effort
6. **Report Stage** — Print success message and directory structure

### Error Handling

Each validation check triggers immediate exit with a non-zero status code and an error message to stdout. The script does not attempt partial cleanup on failure — validation runs before any filesystem changes, so a failed run never leaves a partially created project on disk.

The Git Init stage runs only after the full file structure already exists successfully, so it follows a different error-handling policy: any failure there (missing `git`, `git init`/`add`/`commit` failing) is non-fatal. The script prints a warning and continues to the Report stage with exit code 0 — scaffolding success is never coupled to git succeeding.

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
mkdir -p "$PROJECT_NAME/tests"
mkdir -p "$PROJECT_NAME/specs"
mkdir -p "$PROJECT_NAME/.claude/commands"
```

Uses `mkdir -p` to create the full tree in minimal calls. The directories created:

```
{PROJECT_NAME}/
├── src/{MODULE_NAME}/
├── tests/
├── specs/
└── .claude/commands/
```

### 4. File Generation

All files are written using `cat` with heredocs. The content is deterministic given the inputs.

#### Files Created

| Path | Content Summary |
|------|----------------|
| `src/{MODULE_NAME}/__init__.py` | Empty file (Python package marker) |
| `tests/__init__.py` | Empty file (Python package marker) |
| `tests/test_{MODULE_NAME}.py` | Placeholder pytest test module: imports `pytest`, one trivially-passing test function decorated with `@pytest.mark.smoke` |
| `pyproject.toml` | Declares `pytest` as a dev dependency; registers the `smoke` pytest marker |
| `specs/requirements.md` | Markdown template with heading and placeholder |
| `specs/design.md` | Markdown template with heading and placeholder |
| `specs/tasks.md` | Markdown template with heading and placeholder |
| `.claude/commands/spec-requirements.md` | Slash command for requirements generation |
| `.claude/commands/spec-design.md` | Slash command for design generation |
| `.claude/commands/spec-tasks.md` | Slash command for task breakdown |
| `.claude/commands/implement-task.md` | Slash command for task implementation |
| `.claude/commands/review.md` | Slash command for code review |
| `.gitignore` | Python + macOS ignore patterns |

#### Placeholder Test Content

```python
import pytest


@pytest.mark.smoke
def test_placeholder():
    assert True
```

The placeholder test imports `pytest` and decorates the test function with `@pytest.mark.smoke`, satisfying Requirement 3.7/3.8's "uses the pytest library" criterion. It still does not import the Python_Package itself. With a `src/` layout, importing the package from `tests/` requires either an editable install or additional `pyproject.toml`/`conftest.py` path configuration beyond dependency declaration, which is out of scope for this iteration (see Design Decisions). Omitting the package import keeps `pytest` runnable immediately after scaffolding, with zero extra configuration, while still proving the test discovery path (`tests/` as a package, `test_*.py` naming, a `test_*` function using a real pytest marker) is wired up correctly.

#### pyproject.toml Content

```toml
[project]
name = "{PROJECT_NAME}"
version = "0.1.0"

[project.optional-dependencies]
dev = ["pytest"]

[tool.pytest.ini_options]
markers = [
    "smoke: marks a test as a smoke test",
]
```

`{PROJECT_NAME}` is substituted verbatim, consistent with how the same value is interpolated elsewhere in the script (e.g. the success message) — no additional TOML-escaping is performed beyond the existing Requirement 2 path-safety checks. The `[project.optional-dependencies].dev` group declares `pytest` as a development dependency (Requirement 3.9). The `[tool.pytest.ini_options].markers` list registers `smoke` (Requirement 3.10) so pytest does not emit a `PytestUnknownMarkWarning` when the placeholder test's `@pytest.mark.smoke` decorator runs. No `[build-system]` table is included — the generated project is not intended to be built/published as a distributable package, only run and tested locally, so a build backend is out of scope.

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

- `spec-requirements.md` → read/refine `specs/requirements.md` (user stories + acceptance criteria); additionally embeds a `## Before writing or editing anything` section (see below) that gates edits on resolving blocking ambiguities first
- `spec-design.md` → read `specs/requirements.md` + `specs/design.md`, refine the design
- `spec-tasks.md` → read all three specs, refine `specs/tasks.md`
- `implement-task.md` → read `specs/tasks.md` + `specs/design.md`, implement the next unchecked task
- `review.md` → read all specs and the source tree, review the implementation against them

#### `spec-requirements.md` — "Before writing or editing anything" section

Embedded verbatim as a heredoc block within `spec-requirements.md`'s content, ahead of the read/refine instructions, so Claude evaluates ambiguity before touching `requirements.md`:

```
## Before writing or editing anything

If any part of the scope is unclear, ambiguous, or could reasonably be
interpreted more than one way — target users/roles, feature boundaries,
edge cases, priority/must-have vs nice-to-have, measurable thresholds for
acceptance criteria, etc. — stop and ask control questions before drafting
or changing requirements.md.

- Ask one question at a time, or a small batch of tightly related ones.
- Each question must offer 2-4 concrete, mutually exclusive multiple-choice
  options (plus the user can always answer "Other" with free text).
- Use the `AskUserQuestion` tool so the options are clickable. Only fall
  back to a lettered list (A/B/C/D) in chat if that tool isn't available.
- Do not proceed to writing or editing requirements.md until blocking
  ambiguities are resolved. Minor, non-blocking assumptions can just be
  stated inline in the requirement instead of asked about.
```

This content is static (no variable substitution) and identical across every generated project, since it governs Claude's process rather than any project-specific detail.

### 5. Git Initialization

```bash
GIT_INITIALIZED=0
if command -v git >/dev/null 2>&1; then
    if (cd "$PROJECT_NAME" && git init -q && git add -A && git commit -q -m "Initial project creation") >/dev/null 2>&1; then
        GIT_INITIALIZED=1
    else
        echo "Warning: git initialization or commit failed; skipping repository setup."
    fi
else
    echo "Warning: git not found; skipping repository initialization."
fi
```

Design notes:
- Runs in a subshell (`(cd "$PROJECT_NAME" && ...)`) so the script's own working directory is unaffected regardless of success or failure.
- `git init -q`, `git add -A`, and `git commit -q -m "..."` are chained with `&&` so any failure short-circuits the rest and falls through to the warning branch — no partial-commit state to reason about.
- Always runs `git init` inside Project_Root, even if the current working directory is already part of another git repository (Requirement 9.4) — no detection/skip logic for nested repositories.
- Does not pass `-c user.name=`/`-c user.email=` or run `git config`; the commit relies entirely on the user's existing global git configuration (Requirement 9.5). If that configuration is missing, `git commit` fails and is caught by the same warning branch as any other git failure.
- Both git's own stdout/stderr are suppressed (`>/dev/null 2>&1`), and the script prints its own fixed warning text instead. This keeps the warning message deterministic and testable regardless of the installed git version's exact wording.
- `GIT_INITIALIZED` is tracked but not currently branched on by the Report stage — the Report stage's output is unconditional (see below); the variable exists so a future iteration could report git status without restructuring this stage.

### 6. Success Reporting

```bash
echo ""
echo "Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Directory structure:"
find "$PROJECT_NAME" -print | sed -e "s;[^/]*/;  ;g;s;  \([^ ]\);├─ \1;"
```

The directory structure display uses commands available on default macOS (`find`, `sed`) to render a tree without requiring the `tree` package. The success message and tree are printed regardless of whether Git Init succeeded, since Requirement 9.6/9.7 require the script to still report overall success in that case; any git warning was already printed during the Git Init stage, immediately above this output.

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
             Git Init (best-effort; warn on failure, never exits non-zero)
                    │
                    ▼
             stdout (success message + tree)
```

## Interface

### Inputs
- **stdin**: Project name (line 1), Module name (line 2)

### Outputs
- **stdout**: Prompts, success message, directory tree (on success); error messages (on validation failure); a git warning message (on git unavailability/failure)
- **Exit code**: 0 on success (including when Git Init fails or is skipped), non-zero on validation failure
- **Filesystem**: Complete project directory tree at `./{PROJECT_NAME}/`; if `git` is available and succeeds, `./{PROJECT_NAME}/` is also a git repository containing a single commit ("Initial project creation") with all generated files tracked and a clean working tree

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
- **Git initialization is best-effort, not a hard requirement**: The script runs `git init`/`git add -A`/`git commit` after the file structure is fully written, but treats any failure (missing `git`, failed commit) as a warning rather than a fatal error — scaffolding success (file creation) and git success are decoupled, so a machine without git, or without a configured git identity, still gets a fully scaffolded project and exit code 0.
- **Always `git init` in Project_Root, no nested-repo detection**: The script does not check whether the current working directory is already inside another git repository before running `git init`. This keeps the logic simple (one unconditional `git init` call) at the cost of occasionally creating a nested repository when scaffolding inside an existing repo — accepted per Requirement 9.4.
- **Rely on global git identity, never set or override it**: The script does not pass `-c user.name=`/`-c user.email=` or call `git config`. This avoids stamping commits with placeholder identities that don't match the actual developer, at the cost of the commit silently failing (caught by the warning branch) on a machine with no git identity configured at all.
- **`pyproject.toml` declares pytest but does not wire up the src-layout import**: A `tests/` package (`__init__.py` + placeholder `test_{MODULE_NAME}.py`) and a `pyproject.toml` declaring `pytest` as a dev dependency are created alongside `src/`, but package installation (editable install, `[build-system]`, `src`-layout path configuration) is intentionally out of scope for this iteration. The placeholder test avoids importing the Python_Package so `pytest` passes out of the box with zero setup beyond installing the declared dev dependency; wiring the package to be importable from `tests/` is left to the user.
- **Top-level `tests/` vs. nested under `src/{MODULE_NAME}/tests/`**: Tests are placed at `{PROJECT_NAME}/tests/`, matching the `src/` sibling convention common in modern Python packaging (e.g. `setuptools`/`hatch` src-layouts), rather than nesting them inside the package directory.
- **`pyproject.toml` over `requirements-dev.txt`**: The dev dependency is declared in `pyproject.toml`'s `[project.optional-dependencies]` rather than a separate `requirements-dev.txt`, keeping a single manifest file and aligning with modern (PEP 621) Python packaging conventions rather than the older pip-specific requirements-file convention.
- **Custom `smoke` marker over a built-in pytest marker**: The placeholder test uses a project-defined `@pytest.mark.smoke` marker (registered in `pyproject.toml`) rather than a built-in marker like `@pytest.mark.skip`, since built-in markers like `skip`/`xfail` would make the test not actually pass/run. Registering the custom marker in `[tool.pytest.ini_options]` avoids `PytestUnknownMarkWarning`.

## Constraints

- Uses only `/bin/bash` and default macOS commands: `echo`, `read`, `mkdir`, `cat`, `find`, `sed`, `command`
- `git` is used opportunistically (Requirement 9) but is not a hard dependency — its absence is detected via `command -v git` and degrades gracefully rather than violating the "no additional tools required" constraint of Requirement 7
- Single-file script, no external dependencies
- No network access required
- All file content is static templates (no dynamic fetching)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Input-to-directory-name fidelity

*For any* valid project name and valid module name provided as input, the script SHALL create a directory named exactly as the project name, containing `src/{module_name}/` as a subdirectory.

**Validates: Requirements 1.3, 1.4, 3.1, 3.2, 3.3**

### Property 2: Complete directory structure invariant

*For any* valid input pair (project name, module name), the script SHALL create all required directories and files: `src/{module_name}/__init__.py`, `tests/__init__.py`, `tests/test_{module_name}.py`, `pyproject.toml`, `specs/requirements.md`, `specs/design.md`, `specs/tasks.md`, `.claude/commands/spec-requirements.md`, `.claude/commands/spec-design.md`, `.claude/commands/spec-tasks.md`, `.claude/commands/implement-task.md`, `.claude/commands/review.md`, `.gitignore`.

**Validates: Requirements 3.4, 3.5, 3.6, 3.7, 3.9, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.1**

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

### Property 8: spec-requirements.md control-question gate content

*For any* valid input pair, the generated `.claude/commands/spec-requirements.md` file SHALL contain a `## Before writing or editing anything` heading, and its body SHALL reference: asking control questions before drafting/changing `requirements.md` on ambiguity, asking one question (or a small tightly-related batch) at a time, offering 2-4 mutually exclusive options plus "Other", use of the `AskUserQuestion` tool with an A/B/C/D fallback, and withholding edits until blocking ambiguities are resolved.

**Validates: Requirement 5.7**

### Property 9: Test package validity

*For any* valid input pair, `tests/__init__.py` SHALL exist, `tests/test_{module_name}.py` SHALL exist, contain an `import pytest` statement, define at least one function whose name is prefixed with `test_` and decorated with `@pytest.mark.smoke`, and running `pytest` from within the Project_Root SHALL exit with status 0.

**Validates: Requirements 3.5, 3.6, 3.7, 3.8**

### Property 10: Project manifest completeness

*For any* valid input pair, the generated `pyproject.toml` file SHALL exist at Project_Root, SHALL declare `pytest` as a dependency (under `[project.optional-dependencies].dev`), and SHALL register the `smoke` marker under `[tool.pytest.ini_options].markers`.

**Validates: Requirements 3.9, 3.10**

### Property 11: Git repository initialization completeness

*For any* valid input pair, when `git` is available on `PATH` and a global git identity is configured, the script SHALL create a `.git/` directory inside Project_Root, `git log` inside Project_Root SHALL show exactly one commit whose message is `Initial project creation`, that commit SHALL include every path required by Property 2, and `git status --porcelain` inside Project_Root SHALL report a clean working tree afterward.

**Validates: Requirements 9.1, 9.2, 9.3, 9.4**

### Property 12: Graceful degradation without git

*For any* valid input pair, when `git` is not available on `PATH`, the script SHALL still create the complete file structure (satisfying Property 2), SHALL print a warning message to stdout, SHALL exit with status code 0, and SHALL NOT create a `.git/` directory inside Project_Root.

**Validates: Requirements 9.6, 9.7**
