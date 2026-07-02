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
