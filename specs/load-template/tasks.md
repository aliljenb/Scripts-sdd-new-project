# Tasks: load-template

## Status

- [x] Draft
- [x] In Review
- [x] Approved

## How to use this file

Each task must name the exact file(s) and function/class/method it creates
or changes, and cite the design.md section it implements. Vague tasks
("wire up the backend") are not allowed — split them until each one is a
single, independently completable unit of work with a clear file target.

## Note on layout

design.md's Domain Model, Application Layer, Infrastructure, API Layer, and
Frontend Design sections are all N/A for this feature (see design.md §
Domain Model rationale) — `new-sdd-project.sh` is a single Bash script with
no `src/<python_module>/` layers of its own. Tasks below are derived from
design.md's **Script Design** section instead, all targeting
`new-sdd-project.sh` unless noted. The file currently contains only a
shebang, so every function below is a fresh implementation, not a diff
against existing code.

## Script Implementation

- [x] `new-sdd-project.sh` — implement `sanitize_module_name(input)` per
      design.md § Script Design → Functions and § Pipeline step 2
      (camelCase word-splitting, non-identifier chars → `_`, collapse
      repeats, lowercase, strip stray leading/trailing `_`, `_module`
      fallback if empty, `_`-prefix if leading digit)
- [x] `new-sdd-project.sh` — implement `prompt_project_name()` per
      design.md § Pipeline step 1 (Story 1)
- [x] `new-sdd-project.sh` — implement `validate_project_name(name)` per
      design.md § Pipeline step 1 and § Error Handling (empty name; name
      containing `/` or starting with `-`) (Story 2)
- [x] `new-sdd-project.sh` — implement `prompt_module_name(suggested)` per
      design.md § Pipeline step 3 (Story 1), resolving empty input to
      `suggested`
- [x] `new-sdd-project.sh` — implement `validate_module_name(name)` per
      design.md § Pipeline step 4 and § Error Handling (must match
      `^[a-zA-Z_][a-zA-Z0-9_]*$`) (Story 2)
- [x] `new-sdd-project.sh` — implement `check_project_root_available(name)`
      per design.md § Pipeline step 5 and § Error Handling (Story 2)
- [x] `new-sdd-project.sh` — implement `check_git_available()` per
      design.md § Pipeline step 6 and § Error Handling — hard failure
      before any clone attempt (Story 4)
- [x] `new-sdd-project.sh` — implement `clone_template(staging_dir)` per
      design.md § Pipeline steps 7-8, § Template URL resolution, and §
      Error Handling: resolve
      `TEMPLATE_URL="${SDD_TEMPLATE_URL:-https://github.com/aliljenb/Scripts-sdd-template.git}"`,
      `mktemp -d` the staging directory, clone `TEMPLATE_URL` into it, and
      on clone failure remove the staging directory and exit non-zero
      without touching the Project_Root path (Story 3, Story 4)
- [x] `new-sdd-project.sh` — implement
      `rename_placeholder_package(staging_dir, module_name)` per design.md
      § Pipeline step 9 (rename `<staging_dir>/src/python_module` to
      `<staging_dir>/src/<module_name>`) (Story 3)
- [x] `new-sdd-project.sh` — implement
      `generate_pyproject(staging_dir, project_name)` per design.md §
      Pipeline step 10 and § What the script still generates (write
      `<staging_dir>/pyproject.toml` declaring `project_name`, `pytest` as
      a dev dependency, and the `smoke` marker, overwriting any
      `pyproject.toml` the template shipped) (Story 3)
- [x] `new-sdd-project.sh` — implement `generate_readme(staging_dir, project_name)`
      per design.md § Pipeline step 11 and § What the script still generates
      (write `<staging_dir>/README.md` with a top-level heading containing
      `project_name` and a short generic placeholder description line,
      overwriting any `README.md` the template shipped) (Story 3)
- [x] `new-sdd-project.sh` — update `main()` to call
      `generate_readme "$staging_dir" "$project_name"` immediately after
      `generate_pyproject`, per design.md § Pipeline step 11 (Story 3)
- [x] `new-sdd-project.sh` — implement `finalize_git_repo(project_root)`
      per design.md § Pipeline steps 11-13: remove the (already-staged,
      now-moved) `.git` directory, then `git init -q && git add -A &&
      git commit -q -m "Create initial project"` at `project_root` (Story 3)
- [x] `new-sdd-project.sh` — implement `report_success(project_root)` per
      design.md § Pipeline step 14 (unchanged from the prior
      implementation: success message plus a `find`-based directory tree
      that excludes `.git`)
- [x] `new-sdd-project.sh` — implement `main()` per design.md § Pipeline
      (steps 1-14 in order: prompt/validate project name → compute
      suggestion → prompt/validate module name → check Project_Root
      availability → check `git` availability → `mktemp -d` staging dir →
      clone → rename placeholder package → generate `pyproject.toml` →
      move staging dir to `project_root` → `finalize_git_repo` →
      `report_success`), propagating the first failure's exit code and
      stopping the pipeline immediately on any failure

## Tests

- [x] `tests/fixtures/build_template_fixture.sh` — new helper script that
      builds a local git repository fixture (containing
      `src/python_module/__init__.py`, a `tests/` dir, a `.claude/skills/`
      dir, and a `.gitignore`) usable as the value of `SDD_TEMPLATE_URL`,
      per design.md § Testing Strategy
- [x] `tests/test_scaffold.sh` — update to `export SDD_TEMPLATE_URL` to the
      fixture built by `build_template_fixture.sh` before invoking
      `new-sdd-project.sh`, per design.md § Testing Strategy
- [x] `tests/test_scaffold.sh` — remove assertions tied to the retired
      heredoc-generation behavior: `.claude/commands/*.md` contents,
      `.claude/CLAUDE.md` contents, `.gitignore` pattern contents, and
      `specs/*.md` heading contents (Tasks 5, 6, 7, 27, 40 in the current
      file), per design.md § Testing Strategy → Assertions to remove
- [x] `tests/test_scaffold.sh` — add assertions that the fixture's own
      `tests/`, `.claude/skills/`, and `.gitignore` land unmodified at the
      Project_Root (content matches the fixture, not script-generated),
      per design.md § What the script still generates
- [x] `tests/test_scaffold.sh` — add assertions for
      `rename_placeholder_package`: `src/<module_name>/` exists and
      `src/python_module/` does not, for both a typed module name and the
      suggested default, per design.md § Pipeline step 9 (Story 3)
- [x] `tests/test_scaffold.sh` — add assertions for `generate_pyproject`:
      `pyproject.toml` declares the project name, `pytest` as a dev
      dependency, and the `smoke` marker, and overwrites a
      `pyproject.toml` present in the fixture, per design.md § Pipeline
      step 10 (Story 3)
- [x] `tests/test_scaffold.sh` — add an assertion for `check_git_available`:
      with `git` hidden from `PATH`, the script exits non-zero with an
      error message and performs no clone (no staging directory or
      Project_Root created), per design.md § Error Handling (Story 4)
- [x] `tests/test_scaffold.sh` — add an assertion for `clone_template`
      failure handling: pointing `SDD_TEMPLATE_URL` at a nonexistent path
      causes a non-zero exit and leaves no Project_Root directory behind,
      per design.md § Pipeline step 8 (Story 4)
- [x] `tests/test_scaffold.sh` — keep unchanged: the `git init`/commit
      assertions (exactly one commit, message `Create initial project`,
      clean working tree) and the `.git`-excluded directory-tree assertion,
      per design.md § Pipeline steps 13-14
- [x] `tests/test_properties.sh` — update to `export SDD_TEMPLATE_URL` to
      the fixture built by `build_template_fixture.sh` (same as
      `test_scaffold.sh`), keeping its existing random valid/invalid
      project- and module-name generators (Stories 1-2 unchanged), per
      design.md § Testing Strategy. Scope expanded beyond the original
      wording of this task (see implementation-notes.md): 10 of the file's
      16 properties asserted retired heredoc-generated content and were
      removed or rewritten against the fixture; 2 new properties were added
      for Story 3/4 behavior (placeholder rename, clone-failure safety).

- [x] `tests/fixtures/build_template_fixture.sh` — add a placeholder
      `README.md` to the fixture (distinct sentinel content, mirroring the
      existing placeholder `pyproject.toml`) so `generate_readme`'s
      overwrite behavior is actually exercised, per design.md § Testing
      Strategy
- [x] `tests/test_scaffold.sh` — add assertions for `generate_readme`:
      `README.md` exists, contains a top-level heading with the project
      name, and overwrites the fixture's placeholder `README.md`, per
      design.md § Pipeline step 11 (Story 3)
- [x] `tests/test_properties.sh` — add a "Readme manifest completeness"
      property (parallel to Property 10 for `pyproject.toml`): for
      randomized project/module names, `README.md` exists, its heading
      contains the project name, and it overwrites the fixture's
      placeholder, per design.md § Pipeline step 11 (Story 3)
- [x] `tests/test_properties.sh` — add `README.md` to Property 2's
      `required_paths` list and to Property 11's `required_tracked_paths`
      list, per design.md § What the script still generates

## Task Dependencies

- The `clone_template`, `rename_placeholder_package`, `generate_pyproject`,
  and `finalize_git_repo` tasks each depend on `check_git_available` and
  `check_project_root_available` being implemented first (per pipeline
  ordering in design.md § Pipeline).
- `main()` depends on every other `new-sdd-project.sh` task above being
  implemented first, since it only orchestrates them.
- `tests/fixtures/build_template_fixture.sh` must exist before any
  `tests/test_scaffold.sh` or `tests/test_properties.sh` task that
  references `SDD_TEMPLATE_URL`.
- All `tests/test_scaffold.sh` and `tests/test_properties.sh` tasks depend
  on the corresponding `new-sdd-project.sh` function(s) being implemented.
- `generate_readme` must be implemented before the `main()` update that
  calls it; both must land before any new `README.md`-related test task.
- The fixture's placeholder `README.md` must be added before the
  `test_scaffold.sh`/`test_properties.sh` tasks that assert the overwrite
  behavior.
