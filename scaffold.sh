#!/bin/bash

echo "Enter project name:"
read -r PROJECT_NAME

echo "Enter Python module name:"
read -r MODULE_NAME

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

# Pre-existing path check (reject any existing file or directory, not just directories)
if [ -e "$PROJECT_NAME" ]; then
    echo "Error: '$PROJECT_NAME' already exists."
    exit 1
fi

mkdir -p "$PROJECT_NAME/src/$MODULE_NAME"
mkdir -p "$PROJECT_NAME/specs"
mkdir -p "$PROJECT_NAME/.claude/commands"

touch "$PROJECT_NAME/src/$MODULE_NAME/__init__.py"

cat > "$PROJECT_NAME/specs/requirements.md" << 'EOF'
# Requirements

<!-- Define your project requirements here -->
EOF

cat > "$PROJECT_NAME/specs/design.md" << 'EOF'
# Design

<!-- Define your project design here -->
EOF

cat > "$PROJECT_NAME/specs/tasks.md" << 'EOF'
# Tasks

<!-- Define your project tasks here -->
EOF

cat > "$PROJECT_NAME/.claude/commands/spec-requirements.md" << 'EOF'
Read the file `specs/requirements.md` and help me create or refine the project requirements.

Follow these guidelines:
- Use the format: "As a [role], I want [feature], so that [benefit]"
- Include acceptance criteria for each requirement
- Group requirements logically
- Ensure requirements are testable and measurable

Update `specs/requirements.md` with the refined requirements.
EOF

cat > "$PROJECT_NAME/.claude/commands/spec-design.md" << 'EOF'
Read the files `specs/requirements.md` and `specs/design.md` and help me create or refine the technical design.

Follow these guidelines:
- Define the system architecture and component interactions
- Describe data models and interfaces
- Include error handling strategies
- Document key design decisions and trade-offs
- Define correctness properties that can be tested

Update `specs/design.md` with the refined design.
EOF

cat > "$PROJECT_NAME/.claude/commands/spec-tasks.md" << 'EOF'
Read the files `specs/requirements.md`, `specs/design.md`, and `specs/tasks.md` and help me create or refine the task breakdown.

Follow these guidelines:
- Break down the design into implementable tasks
- Order tasks by dependency (earlier tasks should not depend on later ones)
- Each task should be small enough to implement in one session
- Include sub-tasks where appropriate
- Mark task status with checkboxes

Update `specs/tasks.md` with the refined task breakdown.
EOF

cat > "$PROJECT_NAME/.claude/commands/implement-task.md" << 'EOF'
Read the files `specs/tasks.md` and `specs/design.md` and implement the next unchecked task.

Follow these guidelines:
- Find the first unchecked task (marked with `- [ ]`) in `specs/tasks.md`
- Read the design document for implementation guidance
- Write the code to implement the task
- Write tests for the implementation
- Mark the task as complete (change `- [ ]` to `- [x]`) in `specs/tasks.md`

After implementation, run the tests to verify correctness.
EOF

cat > "$PROJECT_NAME/.claude/commands/review.md" << 'EOF'
Read the files `specs/requirements.md`, `specs/design.md`, and the source code, then perform a code review.

Follow these guidelines:
- Check that the implementation matches the design document
- Verify all requirements have been addressed
- Look for potential bugs, edge cases, and error handling gaps
- Suggest improvements for code quality, readability, and maintainability
- Check that tests adequately cover the implementation

Provide a structured review with findings and recommendations.
EOF

cat > "$PROJECT_NAME/.gitignore" << 'EOF'
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
EOF

echo ""
echo "Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Directory structure:"
find "$PROJECT_NAME" -print | sed -e "s;[^/]*/;  ;g;s;  \([^ ]\);├─ \1;"
