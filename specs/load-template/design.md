# Design: load-template

## Status

- [x] Draft
- [x] In Review
- [x] Approved

## Overview

`new-sdd-project.sh` is a single Bash script with no runtime dependents — it
has no `src/<python_module>/` layers of its own (this repo *builds* SDD
Python projects, it isn't one). Stories 1 and 2 (prompt for project/module
name, validate input) are unchanged from the prior implementation. Stories 3
and 4 replace the old heredoc-based generation of `src/`, `tests/`,
`.claude/skills/`, spec templates, and `.gitignore` with: clone the fixed
Template_Repository into a `mktemp -d` staging directory, rename the
Placeholder_Package (`src/python_module/`) to the user's module name,
generate `pyproject.toml` and `README.md` in place (the two files that
still need script-side generation — `pyproject.toml` embeds the project
name, and `README.md` is deliberately script-authored instead of using the
template's own copy, per Story 3), strip the staging directory's `.git`,
move the staging directory to the final Project_Root path, and
re-initialize a fresh local git repo there. Building
in a staging directory and only `mv`-ing it into place on full success is
what satisfies Story 4's "no partially-created Project_Root" requirement —
failures at any step never touch the real target path.

## Domain Model

Not applicable. Per `.claude/rules/domain-driven-design.md` ("do not
introduce DDD patterns merely to satisfy terminology"), this feature has no
entities, value objects, aggregates, domain events, or repositories to
model: it is a linear, single-process shell pipeline with no persistent
identity, no invariant-bearing object graph, and no external data source
that needs a port/adapter abstraction. Introducing e.g. a "Project"
aggregate or a "TemplateRepository" port purely to fill out this section
would be terminology theater, not a real consistency boundary — so this
section, Application Layer, Infrastructure, API Layer, and Frontend Design
below are all marked N/A, with the actual design captured in **Script
Design**.

- Bounded context: N/A
- New/changed aggregates: None
- New domain events: None
- Repository interface changes: None

### Aggregates

None.

### Entities

None.

### Value Objects

None.

### Domain Events

None.

### Domain Exceptions

None — error handling is via script exit codes/stderr messages, see
**Script Design → Error Handling**.

### Repository Interfaces (ports)

None — the one external system dependency (the `git` CLI, used for both
cloning and the final local init/commit) is invoked directly; there is no
swappable persistence mechanism that would justify a port/adapter here.

## Application Layer (Use Cases)

Not applicable — see **Domain Model** rationale. There is no
`application/<aggregate_name>/` layer; the script's single use case
("scaffold a new project") is the pipeline described under **Script
Design**.

### Commands (write use cases)

N/A

### Queries (read use cases)

N/A

### DTOs

N/A

## Infrastructure

Not applicable in the ORM/persistence sense. The only "outside world"
interaction is shelling out to the `git` CLI (clone, then init/add/commit)
— see **Script Design → Functions** (`clone_template`, `finalize_git_repo`).

### Persistence

N/A

### Repository Implementations (adapters)

N/A

## API Layer

Not applicable — no HTTP surface. The script's interface is its CLI
(stdin prompts, stdout/stderr messages, exit codes), documented under
**Script Design**.

### Endpoints

N/A

## Frontend Design

Not applicable — no UI.

### Components

N/A

### State management

N/A

## Script Design

### Pipeline (control flow)

1. Prompt for project name (Story 1); validate non-empty, and — carried
   over from the prior implementation as a defensive check beyond what
   Story 2 explicitly enumerates — reject a value containing `/` or
   starting with `-`, since either would corrupt the later `mkdir`/`mv`
   targets or be misread as a flag.
2. Compute `Suggested_Module_Name` via `sanitize_module_name()` (unchanged
   from the prior implementation: camelCase word-splitting, non-identifier
   chars → `_`, collapse repeats, lowercase, strip stray leading/trailing
   `_`, `_module` fallback if empty, `_`-prefix if leading digit).
3. Prompt for Python module name with the suggestion pre-filled; empty
   input accepts the suggestion (Story 1/2).
4. Validate the resolved module name against `^[a-zA-Z_][a-zA-Z0-9_]*$`
   (Story 2).
5. Verify no file/directory already exists at the Project_Root path
   (Story 2).
6. Verify `git` is on `PATH`; if not, error and exit non-zero **before**
   attempting any clone (Story 4). This replaces the prior implementation's
   soft "warn and skip" handling for a missing `git` — `git` is now a hard
   dependency because it is used for cloning, not just the final commit.
7. Create a staging directory via `mktemp -d`.
8. Clone the Template_Repository into the staging directory. On failure,
   remove the staging directory and exit non-zero (Story 4) — the real
   Project_Root path is never touched.
9. Rename `<staging>/src/python_module/` to `<staging>/src/<module_name>`
   (Story 3).
10. Generate `<staging>/pyproject.toml`, populated with the project name,
    overwriting anything the template shipped at that path (Story 3).
11. Generate `<staging>/README.md`, containing a top-level heading with the
    project name and a short generic placeholder description line,
    overwriting anything the template shipped at that path (Story 3).
12. Remove `<staging>/.git` (Story 3).
13. Move the staging directory to the final Project_Root path.
14. `git init`, `git add -A`, `git commit -m "Create initial project"` at
    the Project_Root (Story 3) — commit message unchanged from the prior
    implementation, kept for consistency with the existing test suite.
15. Print the success message and a `find`-based directory tree that
    excludes `.git` (unchanged from the prior implementation).

### Functions

| Function | Responsibility |
|---|---|
| `sanitize_module_name(input)` | Derive a valid Python-identifier module-name suggestion from a raw project name string. |
| `prompt_project_name()` | Read and return the raw project name from stdin. |
| `validate_project_name(name)` | Reject an empty name or one containing `/` or a leading `-`. |
| `prompt_module_name(suggested)` | Read the module name from stdin, showing `suggested` as the default, and resolve empty input to `suggested`. |
| `validate_module_name(name)` | Reject a name that isn't a valid Python identifier. |
| `check_project_root_available(name)` | Reject a name for which a file/directory already exists. |
| `check_git_available()` | Reject if the `git` binary isn't on `PATH`. |
| `clone_template(staging_dir)` | Clone the Template_Repository into `staging_dir`; clean up and signal failure if the clone fails. |
| `rename_placeholder_package(staging_dir, module_name)` | Rename `staging_dir/src/python_module` to `staging_dir/src/<module_name>`. |
| `generate_pyproject(staging_dir, project_name)` | Write `staging_dir/pyproject.toml` populated with `project_name`. |
| `generate_readme(staging_dir, project_name)` | Write `staging_dir/README.md` with a title heading and placeholder description for `project_name`. |
| `finalize_git_repo(project_root)` | Strip any cloned `.git`, then `git init`/`add`/`commit` at `project_root`. |
| `report_success(project_root)` | Print the success message and the `.git`-excluded directory tree. |
| `main()` | Orchestrate the pipeline above in order and propagate the first failure's exit code. |

### Error handling

| Condition | Message | Exit code | Story |
|---|---|---|---|
| Empty project name | "Project name cannot be empty." | non-zero | 2 |
| Project name contains `/` or starts with `-` | path-safety error | non-zero | (defensive, carried over) |
| Invalid module identifier | "...valid Python identifier." | non-zero | 2 |
| Project_Root already exists | "...already exists." | non-zero | 2 |
| `git` not on `PATH` | "...git not found..." | non-zero | 4 |
| Clone fails (network/host/repo-not-found) | clone error surfaced to the user; staging dir removed, Project_Root untouched | non-zero | 4 |

### Template URL resolution (test seam)

`TEMPLATE_URL="${SDD_TEMPLATE_URL:-https://github.com/aliljenb/Scripts-sdd-template.git}"`.
This env var exists solely so the test suite can point the script at a
local fixture repo instead of the network (see **Testing Strategy**); it is
undocumented and not a user-facing feature. It does **not** reopen the
"Template_Repository URL is fixed / not user-configurable" decision in
requirements.md's Out of Scope — normal invocation never sets it, and the
default is the real fixed URL.

### What the script still generates vs. what comes from the template

| Path | Source |
|---|---|
| `src/<module>/` (incl. `__init__.py`) | Template_Repository (cloned as `src/python_module/`, renamed) |
| `tests/`, `.claude/skills/`, `.claude/rules/`, `.claude/CLAUDE.md`, spec templates, `.gitignore` | Template_Repository, verbatim |
| `pyproject.toml` | Script-generated (needs the project name) |
| `README.md` | Script-generated (deliberately not the template's copy, per Story 3) |

## Single Responsibility Check

| Module/Class | Single responsibility |
|---|---|
| `sanitize_module_name` | Turn a raw string into a valid Python-identifier suggestion. |
| `prompt_project_name` | Read the project name from the user. |
| `validate_project_name` | Decide whether a project name is acceptable. |
| `prompt_module_name` | Read the module name from the user, applying the suggested default. |
| `validate_module_name` | Decide whether a module name is a valid Python identifier. |
| `check_project_root_available` | Decide whether the target path is free to use. |
| `check_git_available` | Decide whether `git` is usable. |
| `clone_template` | Materialize the Template_Repository into a staging directory. |
| `rename_placeholder_package` | Rename the cloned placeholder package to the resolved module name. |
| `generate_pyproject` | Produce `pyproject.toml` content for the new project. |
| `generate_readme` | Produce `README.md` content for the new project. |
| `finalize_git_repo` | Turn the staged directory into a fresh, committed local git repo. |
| `report_success` | Report the outcome to the user. |
| `main` | Sequence the above steps and stop on the first failure. |

## Testing Strategy

Continue the existing convention in `tests/test_scaffold.sh` and
`tests/test_properties.sh` — a dependency-free Bash harness (`assert`
helper, piped-stdin invocation of the real script) — rather than
introducing a new test framework (`tech.md` lists no shell-testing tool,
and none is needed for this pattern).

- **Test isolation from the network**: tests set `SDD_TEMPLATE_URL` to a
  local fixture git repository (created once per test run, containing a
  minimal `src/python_module/__init__.py`, a `tests/` dir, a
  `.claude/skills/` dir, and a `.gitignore`) instead of cloning the real
  GitHub URL. This keeps the suite offline and deterministic. A `tasks.md`
  task will need to add fixture setup (e.g. a `tests/fixtures/template_repo/`
  built via a local `git init` at test-run time).
- **Unchanged assertions to keep**: `git` presence/init behavior — exactly
  one commit, message `Create initial project`, clean working tree,
  `.git` excluded from the printed directory tree — and the prompt/validation
  assertions for Stories 1-2 (empty name, invalid identifier, pre-existing
  directory, suggested-module-name resolution).
- **Assertions to remove or rewrite**: everything in the current
  `tests/test_scaffold.sh` that asserts specific *content* the script used
  to generate itself — `.claude/commands/*.md` contents, `CLAUDE.md`
  contents, `.gitignore` patterns, `specs/*.md` headings — since that
  content now comes from the fixture/Template_Repository, not the script.
  These should be replaced with assertions that the fixture's own files
  landed in the right place (e.g. `.claude/skills/` exists and matches the
  fixture) plus new assertions for Story 3/4 behavior (placeholder-package
  rename, `pyproject.toml` and `README.md` generation and overwrite,
  staging-dir/no-partial-directory-on-failure, `git`-missing hard failure).
  The fixture should ship its own placeholder `README.md` (distinct
  sentinel content, like the existing placeholder `pyproject.toml`) so the
  overwrite behavior is actually exercised.
- **New cases to add**: clone failure (point `SDD_TEMPLATE_URL` at a
  nonexistent path) leaves no Project_Root directory behind; missing `git`
  is simulated by a `PATH` without `git` and asserted to fail before any
  clone attempt.

## Open Questions / Risks

- [ ] The fixture template repo's exact contents (beyond `src/python_module/`)
      aren't pinned down yet — needs to be built as part of the Tests tasks
      in `/spec-tasks`, mirroring whatever `https://github.com/aliljenb/Scripts-sdd-template.git`
      actually contains closely enough that the fixture-vs-real-URL swap is
      safe.
- [ ] If the real Template_Repository ever needs another dynamically
      substituted file besides `pyproject.toml` (e.g. a name placeholder
      elsewhere), this design will need a follow-up revision — out of scope
      for now since requirements.md names only `pyproject.toml` as an
      exception.
