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
