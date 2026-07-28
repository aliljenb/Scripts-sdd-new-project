# Tasks

## Task 1: Create script file with shebang and input prompting

- [x] 1.1 Create `scaffold.sh` with `#!/bin/bash` shebang line
- [x] 1.2 Add `read -r` prompts for project name and module name
- [x] 1.3 Make the script executable (`chmod +x scaffold.sh`)

## Task 2: Implement input validation

- [x] 2.1 Add empty project name check with error message and `exit 1`
- [x] 2.2 Add empty module name check with error message and `exit 1`
- [x] 2.3 Add Python identifier regex validation for module name (`^[a-zA-Z_][a-zA-Z0-9_]*$`)
- [x] 2.4 Add pre-existing directory check with error message and `exit 1`
- [x] 2.5 Verify all validation checks run before any filesystem write

## Task 3: Implement directory creation

- [x] 3.1 Create Project_Root and `src/{MODULE_NAME}/` directory tree with `mkdir -p`
- [x] 3.2 Create `specs/` directory
- [x] 3.3 Create `.claude/commands/` directory

## Task 4: Implement file generation — Python package

- [x] 4.1 Create empty `src/{MODULE_NAME}/__init__.py`

## Task 5: Implement file generation — spec templates

- [x] 5.1 Write `specs/requirements.md` template with heading and placeholder content
- [x] 5.2 Write `specs/design.md` template with heading and placeholder content
- [x] 5.3 Write `specs/tasks.md` template with heading and placeholder content

## Task 6: Implement file generation — Claude CLI slash commands

- [x] 6.1 Write `.claude/commands/spec-requirements.md` slash command
- [x] 6.2 Write `.claude/commands/spec-design.md` slash command
- [x] 6.3 Write `.claude/commands/spec-tasks.md` slash command
- [x] 6.4 Write `.claude/commands/implement-task.md` slash command
- [x] 6.5 Write `.claude/commands/review.md` slash command

## Task 7: Implement file generation — .gitignore

- [x] 7.1 Write `.gitignore` with Python patterns (`__pycache__/`, `*.py[cod]`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, `.pytest_cache/`, `.mypy_cache/`) and `.DS_Store`

## Task 8: Implement success reporting

- [x] 8.1 Print success message to stdout after all operations complete
- [x] 8.2 Display the created directory structure to stdout using `find`/`sed`

## Task 9: Write property-based tests

- [x] 9.1 Write property test: Input-to-directory-name fidelity (Property 1)
  - **Feature: sdd-project-scaffold, Property 1: For any valid project name and valid module name, the script creates a directory named exactly as the project name containing src/{module_name}/**
- [x] 9.2 Write property test: Complete directory structure invariant (Property 2)
  - **Feature: sdd-project-scaffold, Property 2: For any valid input pair, the script creates all required directories and files**
- [x] 9.3 Write property test: .gitignore content completeness (Property 3)
  - **Feature: sdd-project-scaffold, Property 3: For any valid input pair, the .gitignore contains all required patterns**
- [x] 9.4 Write property test: Invalid module name rejection (Property 4)
  - **Feature: sdd-project-scaffold, Property 4: For any string not matching a valid Python identifier, the script exits non-zero and creates no directory**
- [x] 9.5 Write property test: Empty input rejection (Property 5)
  - **Feature: sdd-project-scaffold, Property 5: For any invocation with an empty project name or module name, the script exits non-zero and creates no directory**
- [x] 9.6 Write property test: Pre-existing directory rejection (Property 6)
  - **Feature: sdd-project-scaffold, Property 6: For any project name that already exists as a directory, the script exits non-zero without modifying the existing directory**
- [x] 9.7 Write property test: Success output contains structure (Property 7)
  - **Feature: sdd-project-scaffold, Property 7: For any valid input pair, stdout contains a success message and directory path references**

## Task 10: Manual verification

- [x] 10.1 Run the script interactively end-to-end and confirm the generated project tree matches the design's file manifest
- [x] 10.2 Run the script via piped input (`echo -e "name\nmodule" | ./scaffold.sh`) and confirm identical results

## Task 11: Rename script to `new-sdd-project.sh`

- [x] 11.1 Rename `scaffold.sh` to `new-sdd-project.sh` (`git mv scaffold.sh new-sdd-project.sh`), preserving the executable bit
- [x] 11.2 Update `tests/test_scaffold.sh`: change the `SCAFFOLD` path variable and all assertion messages/comments from `scaffold.sh` to `new-sdd-project.sh`
- [x] 11.3 Update `tests/test_properties.sh`: change the `SCAFFOLD` path variable and header comment from `scaffold.sh` to `new-sdd-project.sh`
- [x] 11.4 Update `.claude/settings.local.json` permission entries referencing the script path, if any point at the old filename
- [x] 11.5 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions still pass against the renamed script

## Task 12: Embed control-question gate in generated `spec-requirements.md`

- [x] 12.1 In `new-sdd-project.sh`, add a `## Before writing or editing anything` section (verbatim per `specs/design.md`) to the `cat > "$PROJECT_NAME/.claude/commands/spec-requirements.md"` heredoc, placed ahead of the existing read/refine instructions
- [x] 12.2 Update this repo's own `.claude/commands/spec-requirements.md` to match, so this project follows the same gate it generates for others
- [x] 12.3 Write property test: spec-requirements.md control-question gate content (Property 8)
  - **Feature: sdd-project-scaffold, Property 8: For any valid input pair, the generated `.claude/commands/spec-requirements.md` contains the `## Before writing or editing anything` heading and its required instructions (ask-before-drafting on ambiguity, one question/small batch at a time, 2-4 mutually exclusive options plus "Other", `AskUserQuestion` tool with A/B/C/D fallback, withhold edits until resolved)**
- [x] 12.4 Run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 8 test

## Task 13: Implement directory creation — tests package

- [x] 13.1 In `new-sdd-project.sh`, add `mkdir -p "$PROJECT_NAME/tests"` to the Create Dirs stage, alongside the existing `src/`, `specs/`, and `.claude/commands/` calls
- [x] 13.2 Update the directory-tree comment/documentation in the script to list `tests/` alongside `src/{MODULE_NAME}/`

## Task 14: Implement file generation — tests package

- [x] 14.1 Create empty `tests/__init__.py`
- [x] 14.2 Write placeholder `tests/test_{MODULE_NAME}.py` containing a single trivially-passing test function (`def test_placeholder():\n    assert True`), with no import of the Python_Package, per `specs/design.md`

## Task 15: Write property-based tests — test package

- [x] 15.1 Update the Property 2 test (Complete directory structure invariant) to also assert the existence of `tests/__init__.py` and `tests/test_{MODULE_NAME}.py`
- [x] 15.2 Write property test: Test package validity (Property 9)
  - **Feature: sdd-project-scaffold, Property 9: For any valid input pair, `tests/__init__.py` exists, `tests/test_{module_name}.py` exists and defines at least one `test_`-prefixed function, and running `pytest` from within the Project_Root exits with status 0**

## Task 16: Manual verification — test package

- [x] 16.1 Run the script interactively end-to-end, `cd` into the generated project, run `pytest`, and confirm it exits 0
- [x] 16.2 Confirm the generated directory tree (via the script's own success-report output) includes `tests/__init__.py` and `tests/test_{MODULE_NAME}.py`, matching the updated design's file manifest
- [x] 16.3 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 9 test

## Task 17: Update placeholder test to use the pytest library

- [x] 17.1 In `new-sdd-project.sh`, update the `tests/test_$MODULE_NAME.py` heredoc to add an `import pytest` statement and decorate `test_placeholder` with `@pytest.mark.smoke`, per the updated `specs/design.md` placeholder test content
- [x] 17.2 Update `tests/test_scaffold.sh` assertions for `tests/test_{module}.py` to check for the `import pytest` statement and the `@pytest.mark.smoke` decorator, in addition to the existing `test_`-function check

## Task 18: Implement file generation — pyproject.toml

- [x] 18.1 In `new-sdd-project.sh`, add a `cat > "$PROJECT_NAME/pyproject.toml"` heredoc writing `[project]` (`name`/`version`), `[project.optional-dependencies]` with `dev = ["pytest"]`, and `[tool.pytest.ini_options]` registering the `smoke` marker, per `specs/design.md`
- [x] 18.2 Add `tests/test_scaffold.sh` assertions: `pyproject.toml` exists, declares `pytest` under the dev dependency group, and registers the `smoke` marker under `[tool.pytest.ini_options]`

## Task 19: Write property-based tests — project manifest & updated test package

- [x] 19.1 Update the Property 2 test (Complete directory structure invariant) to also assert the existence of `pyproject.toml`
- [x] 19.2 Update the Property 9 test (Test package validity) to also assert the `import pytest` statement and `@pytest.mark.smoke` decorator are present in `tests/test_{module_name}.py`
- [x] 19.3 Write property test: Project manifest completeness (Property 10)
  - **Feature: sdd-project-scaffold, Property 10: For any valid input pair, the generated `pyproject.toml` exists at Project_Root, declares `pytest` as a dependency under `[project.optional-dependencies].dev`, and registers the `smoke` marker under `[tool.pytest.ini_options].markers`**

## Task 20: Manual verification — pytest library usage & project manifest

- [x] 20.1 Run the script interactively end-to-end, `cd` into the generated project, run `pytest -q`, and confirm it exits 0 with no `PytestUnknownMarkWarning` in the output
- [x] 20.2 Confirm the generated `pyproject.toml` content matches the design (`[project]`, `[project.optional-dependencies].dev = ["pytest"]`, `[tool.pytest.ini_options].markers` registering `smoke`)
- [x] 20.3 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 10 test

## Task 21: Implement Git Init stage

- [x] 21.1 In `new-sdd-project.sh`, add the Git Init stage after the Write Files stage: check `command -v git`, then run `git init -q && git add -A && git commit -q -m "Initial project creation"` in a subshell (`(cd "$PROJECT_NAME" && ...)`) with git's own output suppressed, printing a fixed `Warning: ...` message to stdout on any failure (missing `git`, or `init`/`add`/`commit` failing), per `specs/design.md` Component 5
- [x] 21.2 Add `tests/test_scaffold.sh` assertions: with `git` available, a valid scaffold run creates a `.git/` directory inside the project, `git log` shows exactly one commit with message `Initial project creation`, and `git status --porcelain` is clean afterward

## Task 22: Write property-based tests — git initialization

- [x] 22.1 Write property test: Git repository initialization completeness (Property 11)
  - **Feature: sdd-project-scaffold, Property 11: For any valid input pair, when git is available on PATH and a global identity is configured, the script creates `.git/` inside Project_Root, `git log` shows exactly one commit whose message is "Initial project creation" covering every path required by Property 2, and `git status --porcelain` reports a clean working tree afterward**
- [x] 22.2 Write property test: Graceful degradation without git (Property 12)
  - **Feature: sdd-project-scaffold, Property 12: For any valid input pair, when git is not available on PATH, the script still creates the complete file structure, prints a warning message, exits 0, and creates no `.git/` directory inside Project_Root**
  - Implementation note: simulate a git-less environment with a minimal `PATH` containing symlinks to every tool the script needs (`bash`, `mkdir`, `cat`, `find`, `sed`, `grep`, `printf`, etc.) but not `git`, so `command -v git` reliably fails without breaking any other stage of the script

## Task 23: Manual verification — git initialization

- [x] 23.1 Run the script interactively end-to-end in a directory with `git` available and a configured global identity; confirm `.git/` exists, `git log -1` shows the "Initial project creation" commit, and `git status --porcelain` is empty
- [x] 23.2 Re-run the script with `PATH` restricted to exclude `git`; confirm the script still completes the full scaffold, prints a git warning, exits 0, and creates no `.git/` directory
- [x] 23.3 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 11 and Property 12 tests

## Task 24: Update initial commit message text

- [x] 24.1 In `new-sdd-project.sh`, change the Git Init stage's commit message from `Initial project creation` to `Create initial project`, per updated Requirement 9.3
- [x] 24.2 Update `tests/test_scaffold.sh`'s commit-message assertion to expect `Create initial project`
- [x] 24.3 Update `tests/test_properties.sh`'s Property 11 commit-message assertion to expect `Create initial project`

## Task 25: Exclude .git/ from the directory structure output

- [x] 25.1 In `new-sdd-project.sh`, update the Report stage's `find` invocation to `find "$PROJECT_NAME" -path "$PROJECT_NAME/.git" -prune -o -print | sed ...`, excluding `.git/` and its contents from the displayed tree, per updated Requirement 8.2 and `specs/design.md` Component 6
- [x] 25.2 Add a `tests/test_scaffold.sh` assertion: for a project scaffolded with `git` available, the success-report stdout output SHALL NOT contain `.git`
- [x] 25.3 Update the Property 7 test (Success output contains structure) in `tests/test_properties.sh` to also assert stdout contains no `.git` reference

## Task 26: Manual verification — commit message & tree output

- [x] 26.1 Run the script interactively end-to-end with `git` available; confirm `git log -1 --pretty=%s` prints `Create initial project` and the printed directory structure contains no `.git` entries
- [x] 26.2 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass with the updated commit message and tree output

## Task 27: Seed source-layout note into the generated design.md template

- [x] 27.1 In `new-sdd-project.sh`, change the `cat > "$PROJECT_NAME/specs/design.md"` heredoc delimiter from quoted (`<< 'EOF'`) to unquoted (`<< EOF`) so `$MODULE_NAME` is interpolated, and append a `## Source Layout Constraint` section stating "All Python code, except test files, SHALL reside inside `src/$MODULE_NAME/`. Test code belongs in `tests/`.", per `specs/design.md`'s `specs/design.md` Template Content
- [x] 27.2 Add `tests/test_scaffold.sh` assertions: the generated `specs/design.md` contains the `## Source Layout Constraint` heading, and its body references the actual module name substituted (e.g. `src/tree_module/`)
- [x] 27.3 Write property test: design.md template source-layout note (Property 13)
  - **Feature: sdd-project-scaffold, Property 13: For any valid input pair, the generated `specs/design.md` contains a `## Source Layout Constraint` heading and states that Python code other than test files resides inside `src/{module_name}/`, with `{module_name}` substituted to the actual Python_Package value**

## Task 28: Manual verification — design.md source-layout note

- [x] 28.1 Run the script interactively end-to-end; open the generated `specs/design.md` and confirm the `## Source Layout Constraint` section is present with the correct module name substituted (not a literal `$MODULE_NAME`)
- [x] 28.2 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 13 test

## Task 29: Add `.idea/` to the generated .gitignore

- [x] 29.1 In `new-sdd-project.sh`, add a `.idea/` line to the `cat > "$PROJECT_NAME/.gitignore"` heredoc, after the existing `.DS_Store` line, per updated `specs/design.md`
- [x] 29.2 Add a `tests/test_scaffold.sh` assertion: the generated `.gitignore` contains `.idea/`
- [x] 29.3 Update the Property 3 test (.gitignore content completeness) in `tests/test_properties.sh` to also assert `.idea/` is present

## Task 30: Manual verification — .gitignore .idea/ entry

- [x] 30.1 Run the script interactively end-to-end; confirm the generated `.gitignore` contains `.idea/`
- [x] 30.2 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the updated Property 3 test

## Task 31: Add all-at-once-vs-one-by-one gate to the generated implement-task.md

- [x] 31.1 In `new-sdd-project.sh`, update the `cat > "$PROJECT_NAME/.claude/commands/implement-task.md"` heredoc to insert a `## Before implementing` section (per `specs/design.md`'s `implement-task.md` — all-at-once vs. one-by-one gate) ahead of the existing "Follow these guidelines" block, instructing Claude to: count unchecked tasks in `specs/tasks.md`; if more than one remains, ask via `AskUserQuestion` (falling back to a lettered list) whether to implement all remaining tasks at once or one at a time; if exactly one remains, skip the question and implement it directly
- [x] 31.2 Append to the same heredoc, after the existing "After implementation, run the tests to verify correctness." line, the "all at once" loop instruction: if the user chose "all at once", repeat the process for each remaining unchecked task in order, and if an error or test failure occurs while implementing any task, stop immediately, leave that task and all subsequent tasks unchecked, and report the failure rather than continuing
- [x] 31.3 Add `tests/test_scaffold.sh` assertions: the generated `.claude/commands/implement-task.md` contains the `## Before implementing` heading, references `AskUserQuestion`, references skipping the question when exactly one task remains, and references stopping on error/test failure without continuing to later tasks
- [x] 31.4 Write property test: implement-task.md all-at-once-vs-one-by-one gate content (Property 14)
  - **Feature: sdd-project-scaffold, Property 14: For any valid input pair, the generated `.claude/commands/implement-task.md` file contains a `## Before implementing` heading, and its body references asking the user (via `AskUserQuestion`) whether to implement all remaining unchecked tasks at once or one at a time when more than one remains, skipping that question when exactly one remains, and stopping immediately without continuing to later tasks if an error or test failure occurs during "all at once" execution**

## Task 32: Manual verification — implement-task.md ask-once gate

- [x] 32.1 Run the script interactively end-to-end; open the generated `.claude/commands/implement-task.md` and confirm the `## Before implementing` section reads correctly and matches `specs/design.md`
- [x] 32.2 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass, including the new Property 14 test

## Task 33: Expand the generated .gitignore to the comprehensive multi-language template

- [x] 33.1 In `new-sdd-project.sh`, replace the `cat > "$PROJECT_NAME/.gitignore"` heredoc body with the full template from `specs/design.md`'s `.gitignore Content` section — `### Java ###`, `### Python ###`, `### Node ###`, `### React / Frontend build ###` (incl. the `# Env files` sub-block), `### IntelliJ IDEA ###`, `### PyCharm ###`, `### VS Code ###`, `### OS ###`, and `### Logs ###` sections, in that order, verbatim
- [x] 33.2 Add `tests/test_scaffold.sh` assertions for representative anchor patterns from each new section (e.g. `*.class` and `target/` for Java, `node_modules/` for Node, `.next/` and `.vercel` for React/Frontend, `.env` for the env-files sub-block, `*.iml` for IntelliJ, `.vscode/\*` for VS Code, `.Spotlight-V100` for OS, `*.log` for Logs), alongside the existing pattern assertions
- [x] 33.3 Update the Property 3 test (.gitignore content completeness) in `tests/test_properties.sh` to also assert the same representative anchor patterns added in 33.2
- [x] 33.4 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass with the expanded .gitignore content

## Task 34: Manual verification — expanded .gitignore

- [ ] 34.1 Run the script interactively end-to-end; diff the generated `.gitignore` against `specs/design.md`'s `.gitignore Content` block and confirm they match exactly
- [ ] 34.2 Confirm the previously-required core patterns (`__pycache__/`, `*.py[cod]`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`, `.pytest_cache/`, `.mypy_cache/`, `.DS_Store`, `.idea/`) are all still present in the expanded file
- [ ] 34.3 Re-run `tests/test_scaffold.sh` and `tests/test_properties.sh` and confirm all assertions pass
