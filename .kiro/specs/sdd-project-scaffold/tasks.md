# Tasks

## Task 1: Create script file with shebang and input prompting

- [ ] 1.1 Create `scaffold.sh` with `#!/bin/bash` shebang line
- [ ] 1.2 Add `read -r` prompts for project name and module name
- [ ] 1.3 Make the script executable (`chmod +x`)

## Task 2: Implement input validation

- [ ] 2.1 Add empty project name check with error message and `exit 1`
- [ ] 2.2 Add empty module name check with error message and `exit 1`
- [ ] 2.3 Add Python identifier regex validation for module name (`^[a-zA-Z_][a-zA-Z0-9_]*$`)
- [ ] 2.4 Add pre-existing directory check with error message and `exit 1`

## Task 3: Implement directory creation

- [ ] 3.1 Create Project_Root and `src/{MODULE_NAME}/` directory tree with `mkdir -p`
- [ ] 3.2 Create `specs/` directory
- [ ] 3.3 Create `tests/` directory
- [ ] 3.4 Create `.claude/commands/` directory

## Task 4: Implement file generation — Python package

- [ ] 4.1 Create empty `src/{MODULE_NAME}/__init__.py`

## Task 5: Implement file generation — spec templates

- [ ] 5.1 Write `specs/requirements.md` template with heading and placeholder content
- [ ] 5.2 Write `specs/design.md` template with heading and placeholder content
- [ ] 5.3 Write `specs/tasks.md` template with heading and placeholder content

## Task 6: Implement file generation — slash commands

- [ ] 6.1 Write `.claude/commands/spec-requirements.md` slash command
- [ ] 6.2 Write `.claude/commands/spec-design.md` slash command
- [ ] 6.3 Write `.claude/commands/spec-tasks.md` slash command
- [ ] 6.4 Write `.claude/commands/implement-task.md` slash command
- [ ] 6.5 Write `.claude/commands/review.md` slash command

## Task 7: Implement file generation — project config files

- [ ] 7.1 Write `.gitignore` with Python patterns (`__pycache__/`, `*.pyc`, `*.pyo`, `.eggs/`, `*.egg-info/`, `dist/`, `build/`, `.venv/`, `venv/`) and `.DS_Store`
- [ ] 7.2 Write `pyproject.toml` with `[project]` section using project name and `[tool.pytest.ini_options]` section
- [ ] 7.3 Write `tests/conftest.py` as an empty pytest conftest

## Task 8: Implement git initialization

- [ ] 8.1 Add `git init` inside the Project_Root after all files are created
- [ ] 8.2 Add `git add -A` to stage all generated files
- [ ] 8.3 Add `git commit -m "Initial creation"` to perform the initial commit

## Task 9: Implement success reporting

- [ ] 9.1 Print success message to stdout after all operations complete
- [ ] 9.2 Display the created directory structure to stdout

## Task 10: Write property-based tests

- [ ] 10.1 Write property test: Input-to-directory-name fidelity (Property 1)
  - **Feature: sdd-project-scaffold, Property 1: For any valid project name and valid module name, the script creates a directory named exactly as the project name containing src/{module_name}/**
- [ ] 10.2 Write property test: Complete directory structure invariant (Property 2)
  - **Feature: sdd-project-scaffold, Property 2: For any valid input pair, the script creates all required directories and files**
- [ ] 10.3 Write property test: .gitignore content completeness (Property 3)
  - **Feature: sdd-project-scaffold, Property 3: For any valid input pair, the .gitignore contains all required patterns**
- [ ] 10.4 Write property test: pyproject.toml reflects project name (Property 4)
  - **Feature: sdd-project-scaffold, Property 4: For any valid project name, pyproject.toml contains the project name and pytest section**
- [ ] 10.5 Write property test: Invalid module name rejection (Property 5)
  - **Feature: sdd-project-scaffold, Property 5: For any string not matching a valid Python identifier, the script exits non-zero and creates no directory**
- [ ] 10.6 Write property test: Git repository initialization (Property 6)
  - **Feature: sdd-project-scaffold, Property 6: For any valid input pair, Project_Root contains .git/ and git log shows commit with message "Initial creation"**
- [ ] 10.7 Write property test: Success output contains structure (Property 7)
  - **Feature: sdd-project-scaffold, Property 7: For any valid input pair, stdout contains a success message and directory path references**
