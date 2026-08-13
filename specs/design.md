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

1. **Prompt Stage** — Read the project name from stdin, validate it, compute a Suggested_Module_Name from it, then prompt for and resolve the module name (typed override or accepted suggestion). See Component 1 for why project-name validation must complete *before* the module-name prompt (the suggestion is derived from the validated project name).
2. **Validate Stage** — Reject invalid Python identifiers (resolved module name) and pre-existing Project_Root directories
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

# Empty project name check
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

# Project name path-safety validation (no path separators, must not start with '-')
if [[ "$PROJECT_NAME" == */* ]] || [[ "$PROJECT_NAME" == -* ]]; then
    echo "Error: Project name must not contain '/' or start with '-'."
    exit 1
fi

SUGGESTED_MODULE_NAME=$(sanitize_module_name "$PROJECT_NAME")

echo "Enter Python module name [$SUGGESTED_MODULE_NAME]:"
read -r MODULE_NAME_INPUT
if [ -z "$MODULE_NAME_INPUT" ]; then
    MODULE_NAME="$SUGGESTED_MODULE_NAME"
else
    MODULE_NAME="$MODULE_NAME_INPUT"
fi
```

Uses `read -r` to prevent backslash interpretation. Prompts go to stdout so they are visible in interactive use, and the script also works when input is piped (e.g. `echo -e "name\nmodule" | ./new-sdd-project.sh`, or `echo -e "name\n" | ./new-sdd-project.sh` to accept the suggested module name) for scripted/test invocation.

Project-name validation (empty + path-safety) runs immediately after that prompt, *before* the module-name prompt is shown — this ordering is required, not incidental: `sanitize_module_name` (below) needs a validated, non-empty `PROJECT_NAME` to compute `SUGGESTED_MODULE_NAME`, and that suggestion must already be known so it can be displayed inside the module-name prompt text itself (Requirement 1.2). This is a deliberate departure from the original design, which read both inputs before validating either.

The suggestion is shown as `[bracketed text]` inside the prompt line rather than via `read`'s readline default-text feature (`read -e -i "$default"`). `-i` only pre-fills the editing buffer when readline is active on an interactive terminal; it is silently ignored when stdin is piped (`echo ... | ./new-sdd-project.sh`), which is how this script is driven in both scripted usage and the test suite. Implementing the default as plain application logic — "empty submitted line → use `$SUGGESTED_MODULE_NAME`" — behaves identically whether the script is run interactively or with piped input, which the readline approach cannot guarantee (see Design Decisions).

### 2. Module Name Suggestion

```bash
sanitize_module_name() {
    local input="$1"
    local result

    # (a) camelCase word boundaries: lower/digit -> Upper, then a run of
    #     2+ uppercase letters followed by Upper+lower (keeps acronym runs
    #     like "HTTP" in "HTTPServer" together as one segment)
    result=$(printf '%s' "$input" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g; s/([A-Z]+)([A-Z][a-z])/\1_\2/g')

    # (b) anything that isn't a letter, digit, or underscore -> underscore
    result=$(printf '%s' "$result" | sed -E 's/[^a-zA-Z0-9_]/_/g')

    # (c) collapse repeated underscores
    result=$(printf '%s' "$result" | sed -E 's/_+/_/g')

    # (d) lowercase (tr, not ${var,,} — macOS ships bash 3.2, which lacks
    #     bash 4's case-conversion parameter expansion)
    result=$(printf '%s' "$result" | tr 'A-Z' 'a-z')

    # (e) strip a trailing underscore produced by (a)-(c) unconditionally,
    #     and a leading one unless the original input itself started with '_'
    result=$(printf '%s' "$result" | sed -E 's/_+$//')
    if [[ "$input" != _* ]]; then
        result=$(printf '%s' "$result" | sed -E 's/^_+//')
    fi

    # Criterion 4: empty sanitized result -> fixed fallback
    if [ -z "$result" ]; then
        result="_module"
    fi

    # Criterion 3: sanitized result starts with a digit -> prefix underscore
    if [[ "$result" =~ ^[0-9] ]]; then
        result="_${result}"
    fi

    printf '%s' "$result"
}
```

This implements Requirement 11's sanitization algorithm as a pure function of `PROJECT_NAME` — no global state, called once from Component 1 right after project-name validation succeeds. Two `sed -E` passes handle camelCase splitting (Requirement 11.2a):

1. `([a-z0-9])([A-Z])` → insert `_` between a lowercase letter/digit and a following uppercase letter (`BasicTest` → `Basic_Test`).
2. `([A-Z]+)([A-Z][a-z])` → insert `_` before the last uppercase letter of an uppercase run when that letter is followed by a lowercase letter, so an acronym run splits as one segment from the word after it (`HTTPServer` → `HTTP_Server`; `My_IOTool` → `My_IO_Tool` once pass 1 has already split `My`/`IOTool`).

Worked examples (also documented in `specs/requirements.md`'s Requirement 11 Examples table):

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

### 3. Input Validation

```bash
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
- Project name: must be non-empty and path-safe (checked in Component 1, before the module-name prompt)
- Module name: the *resolved* value (accepted suggestion or typed override) must match `^[a-zA-Z_][a-zA-Z0-9_]*$` (valid Python identifier). Since `sanitize_module_name` always produces a string matching this pattern by construction, this check only ever rejects a user-*typed* override — but it still runs unconditionally against the resolved value (Requirement 11.6), rather than being skipped for the accepted-suggestion path, so a bug in the sanitizer can never silently produce an invalid `Python_Package` name.
- Project directory: must not already exist in the current working directory

All checks run before any `mkdir`/`cat` call, so validation failures never touch the filesystem.

### 4. Directory Creation

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

### 5. File Generation

All files are written using `cat` with heredocs. The content is deterministic given the inputs.

#### Files Created

| Path | Content Summary |
|------|----------------|
| `src/{MODULE_NAME}/__init__.py` | Empty file (Python package marker) |
| `tests/__init__.py` | Empty file (Python package marker) |
| `tests/test_{MODULE_NAME}.py` | Placeholder pytest test module: imports `pytest`, one trivially-passing test function decorated with `@pytest.mark.smoke` |
| `pyproject.toml` | Declares `pytest` as a dev dependency; registers the `smoke` pytest marker |
| `specs/requirements.md` | Markdown template with heading and placeholder |
| `specs/design.md` | Markdown template with heading, placeholder, and a source-layout design note |
| `specs/tasks.md` | Markdown template with heading and placeholder |
| `.claude/commands/spec-requirements.md` | Slash command for requirements generation |
| `.claude/commands/spec-design.md` | Slash command for design generation |
| `.claude/commands/spec-tasks.md` | Slash command for task breakdown |
| `.claude/commands/implement-task.md` | Slash command for task implementation |
| `.claude/commands/review.md` | Slash command for code review |
| `.claude/CLAUDE.md` | Static development discipline guidance for Claude Code sessions working in the generated project |
| `.gitignore` | Python + macOS ignore patterns |

#### specs/design.md Template Content

```markdown
# Design

<!-- Define your project design here -->

## Source Layout Constraint

All Python code, except test files, SHALL reside inside `src/$MODULE_NAME/`. Test code belongs in `tests/`.
```

Unlike `specs/requirements.md` and `specs/tasks.md` (which stay pure placeholders per Requirement 4.5), the `design.md` template additionally embeds a `## Source Layout Constraint` note with `$MODULE_NAME` substituted to the actual Python_Package name (Requirement 4.6). This requires the heredoc to be unquoted (`<< EOF`, not `<< 'EOF'`) so the shell interpolates `$MODULE_NAME`, the same technique already used for `pyproject.toml`'s `$PROJECT_NAME` substitution. The note seeds every scaffolded project with this source-layout rule already documented in its own design doc, so a downstream developer (or Claude, when driving `/spec-design` in that project) sees the constraint before writing any code, rather than needing to rediscover or re-invent it.

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
### Java ###
*.class
*.jar
*.war
*.ear
*.nar
hs_err_pid*
replay_pid*
target/
.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar
gradle-app.setting
!**/src/main/**/build/
!**/src/test/**/build/

### Python ###
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
ENV/
env.bak/
venv.bak/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
pip-log.txt
pip-delete-this-directory.txt
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/
*.mo
*.pot
instance/
.webassets-cache
.scrapy
docs/_build/
.pybuilder/
target/
.ipynb_checkpoints
profile_default/
ipython_config.py
__pypackages__/
celerybeat-schedule
celerybeat.pid
*.sage.py
.mypy_cache/
.dmypy.json
dmypy.json
.pyre/
.pytype/
cython_debug/

### Node ###
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*
.pnp
.pnp.js
.pnp.cjs

### React / Frontend build ###
dist/
build/
out/
.next/
.nuxt/
.cache/
.parcel-cache/
.eslintcache
.turbo/
.vercel
coverage/
*.tsbuildinfo

# Env files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

### IntelliJ IDEA ###
.idea/
*.iws
*.iml
*.ipr
out/

### PyCharm ###
# (PyCharm uses the same .idea/ folder as IntelliJ, already covered above)
# If you want to keep some shared run configs, you can unignore selectively:
# !.idea/runConfigurations

### VS Code ###
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
*.code-workspace
.history/

### OS ###
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

### Logs ###
logs/
*.log

```

`.idea/` excludes JetBrains IDE project metadata (PyCharm, IntelliJ with the Python plugin), mirroring the treatment of `.DS_Store` for macOS Finder metadata: neither is a Python packaging artifact, but both are per-developer environment noise that should never be tracked. Requirement 6.2's pattern list is introduced with "including," i.e. non-exhaustive, so this addition doesn't require a requirements change.

#### Claude Command Content

Each file in `.claude/commands/` is a plain-text prompt body (no special frontmatter required) that instructs Claude, when the corresponding slash command is invoked, to read the relevant `specs/*.md` files and update them:

- `spec-requirements.md` → read/refine `specs/requirements.md` (user stories + acceptance criteria); additionally embeds a `## Before writing or editing anything` section (see below) that gates edits on resolving blocking ambiguities first
- `spec-design.md` → read `specs/requirements.md` + `specs/design.md`, refine the design
- `spec-tasks.md` → read all three specs, refine `specs/tasks.md`
- `implement-task.md` → read `specs/tasks.md` + `specs/design.md`; if more than one unchecked task remains, ask whether to implement all remaining tasks at once or one at a time before implementing any of them (see below), then implement accordingly
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

#### `implement-task.md` — all-at-once vs. one-by-one gate

Embedded within `implement-task.md`'s content, ahead of the implementation guidelines, so Claude decides the execution mode before touching any task:

```
Read the files `specs/tasks.md` and `specs/design.md` and implement the next unchecked task.

## Before implementing

Count the unchecked tasks (marked with `- [ ]`) in `specs/tasks.md`.
- IF more than one unchecked task remains, ask the user whether to implement
  all remaining unchecked tasks at once or one at a time. Use the
  `AskUserQuestion` tool so the choice is clickable, falling back to a
  lettered list in chat if that tool is unavailable.
- IF exactly one unchecked task remains, skip this question and implement
  it directly.

Follow these guidelines:
- Find the first unchecked task (marked with `- [ ]`) in `specs/tasks.md`
- Read the design document for implementation guidance
- Write the code to implement the task
- Write tests for the implementation
- Mark the task as complete (change `- [ ]` to `- [x]`) in `specs/tasks.md`

After implementation, run the tests to verify correctness.

If the user chose "all at once", repeat this process for each remaining
unchecked task in order. If an error or test failure occurs while
implementing any task, stop immediately, leave that task and all
subsequent tasks unchecked, and report the failure to the user rather
than continuing to later tasks.
```

Design notes:
- The single-task skip (Requirement 5.7) avoids a pointless prompt when there is nothing to choose between — with one task left, "all at once" and "one at a time" are the same outcome.
- The stop-on-failure rule (Requirement 5.8) favors a hard stop over skip-and-continue: letting Claude push through a failed task risks later tasks being implemented against code that doesn't actually work yet, compounding the failure instead of surfacing it early.
- This content is static (no variable substitution) and identical across every generated project, mirroring the `spec-requirements.md` gate above.

#### `.claude/CLAUDE.md` — Development discipline

Written directly into `.claude/` (a sibling of `.claude/commands/`, not inside it), since `CLAUDE.md` is project-wide guidance that Claude Code loads automatically for every session in the project, not a slash command invoked on demand. No new `mkdir` call is required — `.claude/` already exists from the `mkdir -p "$PROJECT_NAME/.claude/commands"` call in the Directory Creation stage.

Content, embedded verbatim via a quoted heredoc (`<< 'EOF'`, matching Requirement 10.13's no-substitution rule):

```
## Development discipline

- Do not modify code unless explicitly asked to implement or change something.
- For investigation/review tasks, inspect the existing implementation first and stop for review before making changes.
- Do not commit or push unless explicitly instructed.
- Preserve unrelated working-tree changes.
- Do not revert existing user changes unless explicitly instructed.
- Keep implementation scope aligned with the approved task.
- Do not invent missing behavior or architectural abstractions before inspecting the existing code.
- When a proposed change has not been verified, clearly distinguish it from verified behavior.
- Prefer small, incremental changes with explicit verification.
- Do not start unrelated work because of stale, duplicated, or automatically generated task prompts.
```

Design notes:
- Placed at `.claude/CLAUDE.md` rather than `.claude/commands/CLAUDE.md` because Claude Code's convention is to auto-load `CLAUDE.md` from the project root / `.claude/` directory as standing instructions, whereas `.claude/commands/*.md` files are only read when their slash command is explicitly invoked. This guidance needs to apply to every session in the generated project, not just SDD-lifecycle commands, so it belongs with the always-loaded file rather than the on-demand ones.
- The content is a fixed, self-contained discipline policy — it does not reference `$PROJECT_NAME`/`$MODULE_NAME` or any other run-specific value, so a quoted heredoc is used (unlike `pyproject.toml`'s or `design.md`'s unquoted heredocs) to guarantee byte-for-byte identical output across every generated project (Requirement 10.13).
- This requirement exists independently of the SDD lifecycle commands (Requirement 5); it governs general engineering discipline (scoped changes, no unapproved commits/reverts, distinguishing verified from unverified work) rather than any specific spec-authoring workflow, which is why it is documented as its own requirement/component rather than folded into the Claude Command Content section above.

### 6. Git Initialization

```bash
GIT_INITIALIZED=0
if command -v git >/dev/null 2>&1; then
    if (cd "$PROJECT_NAME" && git init -q && git add -A && git commit -q -m "Create initial project") >/dev/null 2>&1; then
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

### 7. Success Reporting

```bash
echo ""
echo "Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Directory structure:"
find "$PROJECT_NAME" -path "$PROJECT_NAME/.git" -prune -o -print | sed -e "s;[^/]*/;  ;g;s;  \([^ ]\);├─ \1;"
```

The directory structure display uses commands available on default macOS (`find`, `sed`) to render a tree without requiring the `tree` package. The `-path "$PROJECT_NAME/.git" -prune -o -print` pair excludes `.git/` and everything beneath it from the listing (Requirement 8.2) — `-prune` stops `find` from descending into `.git/` and, because it short-circuits the `-o`, also suppresses printing the `.git/` entry itself, while every other entry still reaches `-print` unaffected. This keeps the tree output focused on the generated project content and stable regardless of git internals (object hashes, pack files, etc.), which would otherwise make the tree output non-deterministic across runs. The success message and tree are printed regardless of whether Git Init succeeded, since Requirement 9.6/9.7 require the script to still report overall success in that case; any git warning was already printed during the Git Init stage, immediately above this output.

## Data Flow

```
User Input ──▶ PROJECT_NAME
                    │
                    ▼
      Project Name Validation Gate (exit 1 on failure)
                    │
                    ▼
      sanitize_module_name() ──▶ SUGGESTED_MODULE_NAME
                    │
                    ▼
      User Input (or empty) ──▶ MODULE_NAME (typed override or accepted suggestion)
                    │
                    ▼
             Validation Gates (module identifier, pre-existing dir; exit 1 on failure)
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
- **stdin**: Project name (line 1), Module name (line 2 — optional; empty input accepts the displayed Suggested_Module_Name instead of erroring)

### Outputs
- **stdout**: Prompts, success message, directory tree (on success); error messages (on validation failure); a git warning message (on git unavailability/failure)
- **Exit code**: 0 on success (including when Git Init fails or is skipped), non-zero on validation failure
- **Filesystem**: Complete project directory tree at `./{PROJECT_NAME}/`; if `git` is available and succeeds, `./{PROJECT_NAME}/` is also a git repository containing a single commit ("Create initial project") with all generated files tracked and a clean working tree

### Usage

```bash
# Interactive
./new-sdd-project.sh

# Piped (for testing)
echo -e "my-project\nmy_module" | ./new-sdd-project.sh

# Piped, accepting the suggested module name (empty second line)
echo -e "BasicTest\n" | ./new-sdd-project.sh   # module name resolves to "basic_test"
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
- **Source-layout constraint documented in `design.md`, not enforced by the Script**: Requirement 4.6 seeds the generated `design.md` template with a note that Python code (except tests) belongs under `src/$MODULE_NAME/`. The Script does not itself enforce this on the downstream project's future code — it only ensures the constraint is documented from day one, on the theory that a scaffolding tool should hand off a documented convention rather than police code the downstream developer (or Claude) hasn't written yet.
- **Suggested module name shown as prompt text, not via `read -e -i`**: Bash's readline default-text mechanism (`read -e -i "$default"`) only pre-fills the input buffer on an interactive terminal; it is a no-op when stdin is piped, which is this script's primary scripted/tested invocation mode. Displaying the suggestion inside the prompt string and resolving "empty submitted line" to the suggestion in plain shell logic instead guarantees identical behavior interactively and non-interactively, at the cost of the suggestion not being directly editable inline (the user retypes it with changes rather than editing pre-filled text).
- **camelCase-to-snake_case via two `sed -E` passes, not a single regex**: `sanitize_module_name` splits camelCase boundaries in two passes — lower/digit-to-upper, then uppercase-run-to-upper+lower — so that acronym runs (`HTTPServer`) collapse to one segment (`http_server`) instead of splitting every capital (`h_t_t_p_server`), matching Requirement 11.2a. A single regex pass cannot distinguish "start of a new capitalized word" from "still inside an acronym run" without this two-step approach.
- **Lowercasing via `tr`, not `${var,,}`**: macOS ships bash 3.2 (Apple stopped bundling bash 4+ over its GPLv3 license), which lacks bash 4's case-conversion parameter expansion. `tr 'A-Z' 'a-z'` is POSIX-portable and works identically on bash 3.2.

## Constraints

- Uses only `/bin/bash` and default macOS commands: `echo`, `read`, `mkdir`, `cat`, `find`, `sed`, `tr`, `command`
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

*For any* valid input pair (project name, module name), the script SHALL create all required directories and files: `src/{module_name}/__init__.py`, `tests/__init__.py`, `tests/test_{module_name}.py`, `pyproject.toml`, `specs/requirements.md`, `specs/design.md`, `specs/tasks.md`, `.claude/commands/spec-requirements.md`, `.claude/commands/spec-design.md`, `.claude/commands/spec-tasks.md`, `.claude/commands/implement-task.md`, `.claude/commands/review.md`, `.claude/CLAUDE.md`, `.gitignore`.

**Validates: Requirements 3.4, 3.5, 3.6, 3.7, 3.9, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.9, 6.1, 10.1**

### Property 3: .gitignore content completeness

*For any* valid input pair, the generated `.gitignore` file SHALL contain all required patterns: `__pycache__/`, `*.py[cod]`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, `.pytest_cache/`, `.mypy_cache/`, `.DS_Store`, and `.idea/`.

**Validates: Requirements 6.2, 6.3**

### Property 4: Invalid module name rejection

*For any* **non-empty** string typed at the module name prompt that does not match the pattern `^[a-zA-Z_][a-zA-Z0-9_]*$`, the script SHALL exit with a non-zero status code and no project directory shall be created. (Empty input at that prompt is excluded from this property — it is not a rejected value, it resolves to the Suggested_Module_Name per Property 16.)

**Validates: Requirements 2.3, 2.5**

### Property 5: Empty project name rejection

*For any* invocation where the project name is empty, the script SHALL exit with a non-zero status code and no project directory shall be created. (An empty *module* name is no longer a rejection case as of Requirement 11 — it now resolves to the Suggested_Module_Name; see Property 16.)

**Validates: Requirements 2.1, 2.5**

### Property 6: Pre-existing directory rejection

*For any* project name that already exists as a directory in the current working directory, the script SHALL exit with a non-zero status code without modifying the existing directory.

**Validates: Requirement 2.4**

### Property 7: Success output contains structure

*For any* valid input pair, the script's stdout SHALL contain a success message and references to the created directory paths, and SHALL NOT contain any `.git` path reference in the displayed directory structure.

**Validates: Requirements 8.1, 8.2**

### Property 8: spec-requirements.md control-question gate content

*For any* valid input pair, the generated `.claude/commands/spec-requirements.md` file SHALL contain a `## Before writing or editing anything` heading, and its body SHALL reference: asking control questions before drafting/changing `requirements.md` on ambiguity, asking one question (or a small tightly-related batch) at a time, offering 2-4 mutually exclusive options plus "Other", use of the `AskUserQuestion` tool with an A/B/C/D fallback, and withholding edits until blocking ambiguities are resolved.

**Validates: Requirement 5.10**

### Property 9: Test package validity

*For any* valid input pair, `tests/__init__.py` SHALL exist, `tests/test_{module_name}.py` SHALL exist, contain an `import pytest` statement, define at least one function whose name is prefixed with `test_` and decorated with `@pytest.mark.smoke`, and running `pytest` from within the Project_Root SHALL exit with status 0.

**Validates: Requirements 3.5, 3.6, 3.7, 3.8**

### Property 10: Project manifest completeness

*For any* valid input pair, the generated `pyproject.toml` file SHALL exist at Project_Root, SHALL declare `pytest` as a dependency (under `[project.optional-dependencies].dev`), and SHALL register the `smoke` marker under `[tool.pytest.ini_options].markers`.

**Validates: Requirements 3.9, 3.10**

### Property 11: Git repository initialization completeness

*For any* valid input pair, when `git` is available on `PATH` and a global git identity is configured, the script SHALL create a `.git/` directory inside Project_Root, `git log` inside Project_Root SHALL show exactly one commit whose message is `Create initial project`, that commit SHALL include every path required by Property 2, and `git status --porcelain` inside Project_Root SHALL report a clean working tree afterward.

**Validates: Requirements 9.1, 9.2, 9.3, 9.4**

### Property 12: Graceful degradation without git

*For any* valid input pair, when `git` is not available on `PATH`, the script SHALL still create the complete file structure (satisfying Property 2), SHALL print a warning message to stdout, SHALL exit with status code 0, and SHALL NOT create a `.git/` directory inside Project_Root.

**Validates: Requirements 9.6, 9.7**

### Property 13: design.md template source-layout note

*For any* valid input pair, the generated `specs/design.md` file SHALL contain a `## Source Layout Constraint` heading, and its body SHALL state that Python code other than test files resides inside `src/{module_name}/`, with `{module_name}` substituted to the actual Python_Package value for that run.

**Validates: Requirement 4.6**

### Property 14: implement-task.md all-at-once-vs-one-by-one gate content

*For any* valid input pair, the generated `.claude/commands/implement-task.md` file SHALL contain a `## Before implementing` heading, and its body SHALL reference: asking the user (via the `AskUserQuestion` tool) whether to implement all remaining unchecked tasks at once or one at a time when more than one unchecked task remains, skipping that question and implementing directly when exactly one unchecked task remains, and — when "all at once" was chosen — stopping immediately and leaving subsequent tasks unchecked if an error or test failure occurs, rather than continuing.

**Validates: Requirements 5.6, 5.7, 5.8**

### Property 15: CLAUDE.md development discipline content completeness

*For any* valid input pair, the generated `.claude/CLAUDE.md` file SHALL contain a `## Development discipline` heading, and its body SHALL instruct that: code is not modified unless explicitly asked to implement or change something; investigation/review tasks inspect the existing implementation first and stop for review before making changes; changes are not committed or pushed unless explicitly instructed; unrelated working-tree changes are preserved; existing user changes are not reverted unless explicitly instructed; implementation scope stays aligned with the approved task; missing behavior or architectural abstractions are not invented before inspecting the existing code; an unverified proposed change is clearly distinguished from verified behavior; small, incremental changes with explicit verification are preferred; and unrelated work is not started because of stale, duplicated, or automatically generated task prompts. The content SHALL be byte-for-byte identical across every generated project (no variable substitution).

**Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9, 10.10, 10.11, 10.12, 10.13**

### Property 16: Suggested module name computation and default acceptance

*For any* valid project name, the Script SHALL compute a Suggested_Module_Name that (a) matches the Python identifier pattern `^[a-zA-Z_][a-zA-Z0-9_]*$`, (b) is deterministic — the same project name always yields the same suggestion, and (c) is displayed as the bracketed default inside the Python module name prompt text. *For any* valid project name, WHEN the user submits empty input at the module name prompt, THE Script SHALL resolve `MODULE_NAME` to the Suggested_Module_Name; WHEN the user submits a non-empty value, THE Script SHALL resolve `MODULE_NAME` to that typed value instead, discarding the suggestion. Additionally, for the specific project names `BasicTest`, `basic-test`, `basic_test`, `HTTPServer`, `MyIOTool`, `123`, `...`, and `_9lives`, the Suggested_Module_Name SHALL exactly equal `basic_test`, `basic_test`, `basic_test`, `http_server`, `my_io_tool`, `_123`, `_module`, and `_9lives` respectively (this last clause is checked against the fixed Examples table in Requirement 11, not randomized inputs, since the camelCase/acronym/digit-prefix/empty-fallback behaviors it covers are edge cases unlikely to be hit by random generation). Note `...` rather than `---` is used for the empty-fallback example: a leading `-` is already rejected by the pre-existing project-name path-safety check (Component 1) before the suggestion is ever computed, so `---` could never reach `sanitize_module_name` in practice.

**Validates: Requirements 1.2, 1.4, 2.2, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7**
