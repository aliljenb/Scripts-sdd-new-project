#!/bin/bash
# Lightweight test harness for new-sdd-project.sh (no external test framework required).
# Extended as each task in specs/tasks.md is implemented.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAFFOLD="$SCRIPT_DIR/new-sdd-project.sh"
FAILURES=0

assert() {
    local description="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "PASS: $description"
    else
        echo "FAIL: $description"
        FAILURES=$((FAILURES + 1))
    fi
}

# --- Task 1: shebang and input prompting ---

assert "new-sdd-project.sh exists" "[ -f '$SCAFFOLD' ]"
assert "new-sdd-project.sh is executable" "[ -x '$SCAFFOLD' ]"
assert "new-sdd-project.sh has a bash shebang" "head -n1 '$SCAFFOLD' | grep -q '^#!/bin/bash$'"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

run_in_workdir() {
    # run_in_workdir <stdin-string>
    local capture="$WORKDIR/.scaffold_out"
    (cd "$WORKDIR" && printf '%s' "$1" | "$SCAFFOLD" >"$capture" 2>&1)
    STATUS=$?
    OUTPUT=$(cat "$capture" 2>/dev/null)
    rm -f "$capture"
    return $STATUS
}

run_in_workdir $'demo-project\ndemo_module\n'; STATUS=$?

assert "new-sdd-project.sh exits 0 given valid piped input" "[ $STATUS -eq 0 ]"
assert "new-sdd-project.sh prompts for project name" "echo \"\$OUTPUT\" | grep -q 'Enter project name:'"
assert "new-sdd-project.sh prompts for module name" "echo \"\$OUTPUT\" | grep -q 'Enter Python module name:'"

# --- Task 2: input validation ---

# Empty project name
run_in_workdir $'\nmodule\n'; STATUS=$?
assert "empty project name exits non-zero" "[ $STATUS -ne 0 ]"
assert "empty project name prints error" "echo \"\$OUTPUT\" | grep -qi 'project name cannot be empty'"

# Empty module name
run_in_workdir $'project\n\n'; STATUS=$?
assert "empty module name exits non-zero" "[ $STATUS -ne 0 ]"
assert "empty module name prints error" "echo \"\$OUTPUT\" | grep -qi 'module name cannot be empty'"

# Invalid Python identifier (module name)
run_in_workdir $'project\nnot-valid\n'; STATUS=$?
assert "invalid module identifier exits non-zero" "[ $STATUS -ne 0 ]"
assert "invalid module identifier prints error" "echo \"\$OUTPUT\" | grep -qi 'valid Python identifier'"
assert "invalid module identifier creates no directory" "[ ! -d '$WORKDIR/project' ]"

# Pre-existing project directory
mkdir -p "$WORKDIR/existing-project"
run_in_workdir $'existing-project\nmodule\n'; STATUS=$?
assert "pre-existing directory exits non-zero" "[ $STATUS -ne 0 ]"
assert "pre-existing directory prints error" "echo \"\$OUTPUT\" | grep -qi 'already exists'"

# Valid input still succeeds (no validation false-positives)
run_in_workdir $'valid-project\nvalid_module\n'; STATUS=$?
assert "valid input still exits 0 after adding validation" "[ $STATUS -eq 0 ]"

# --- Task 3: directory creation ---

run_in_workdir $'tree-project\ntree_module\n'; STATUS=$?
assert "directory creation exits 0" "[ $STATUS -eq 0 ]"
assert "creates Project_Root" "[ -d '$WORKDIR/tree-project' ]"
assert "creates src/{module}/ directory" "[ -d '$WORKDIR/tree-project/src/tree_module' ]"
assert "creates specs/ directory" "[ -d '$WORKDIR/tree-project/specs' ]"
assert "creates .claude/commands/ directory" "[ -d '$WORKDIR/tree-project/.claude/commands' ]"

# --- Task 13: tests/ directory creation ---

assert "creates tests/ directory" "[ -d '$WORKDIR/tree-project/tests' ]"

# --- Task 14: tests package file generation ---

assert "creates tests/__init__.py" "[ -f '$WORKDIR/tree-project/tests/__init__.py' ]"
assert "creates tests/test_{module}.py" "[ -f '$WORKDIR/tree-project/tests/test_tree_module.py' ]"
assert "tests/test_{module}.py defines a test_ function" "grep -q '^def test_' '$WORKDIR/tree-project/tests/test_tree_module.py'"
assert "tests/test_{module}.py does not import the package" "! grep -q 'tree_module' '$WORKDIR/tree-project/tests/test_tree_module.py'"

# --- Task 17: placeholder test uses the pytest library ---

assert "tests/test_{module}.py imports pytest" "grep -q '^import pytest$' '$WORKDIR/tree-project/tests/test_tree_module.py'"
assert "tests/test_{module}.py decorates test with @pytest.mark.smoke" "grep -q '^@pytest.mark.smoke$' '$WORKDIR/tree-project/tests/test_tree_module.py'"

# --- Task 18: pyproject.toml generation ---

PYPROJECT="$WORKDIR/tree-project/pyproject.toml"

assert "creates pyproject.toml" "[ -f '$PYPROJECT' ]"
assert "pyproject.toml declares project name" "grep -q 'name = \"tree-project\"' '$PYPROJECT'"
assert "pyproject.toml declares pytest as a dev dependency" "grep -q 'dev = \[\"pytest\"\]' '$PYPROJECT'"
assert "pyproject.toml registers the smoke marker" "grep -q 'smoke: marks a test as a smoke test' '$PYPROJECT'"

# --- Task 4: Python package __init__.py ---

assert "creates src/{module}/__init__.py" "[ -f '$WORKDIR/tree-project/src/tree_module/__init__.py' ]"

# --- Task 5: spec template file generation ---

assert "creates specs/requirements.md" "[ -f '$WORKDIR/tree-project/specs/requirements.md' ]"
assert "creates specs/design.md" "[ -f '$WORKDIR/tree-project/specs/design.md' ]"
assert "creates specs/tasks.md" "[ -f '$WORKDIR/tree-project/specs/tasks.md' ]"
assert "specs/requirements.md has a heading" "grep -q '^# Requirements$' '$WORKDIR/tree-project/specs/requirements.md'"
assert "specs/design.md has a heading" "grep -q '^# Design$' '$WORKDIR/tree-project/specs/design.md'"
assert "specs/tasks.md has a heading" "grep -q '^# Tasks$' '$WORKDIR/tree-project/specs/tasks.md'"

# --- Task 6: Claude CLI slash command file generation ---

CMD_DIR="$WORKDIR/tree-project/.claude/commands"

assert "creates spec-requirements.md" "[ -f '$CMD_DIR/spec-requirements.md' ]"
assert "creates spec-design.md" "[ -f '$CMD_DIR/spec-design.md' ]"
assert "creates spec-tasks.md" "[ -f '$CMD_DIR/spec-tasks.md' ]"
assert "creates implement-task.md" "[ -f '$CMD_DIR/implement-task.md' ]"
assert "creates review.md" "[ -f '$CMD_DIR/review.md' ]"

assert "spec-requirements.md references specs/requirements.md" "grep -q 'specs/requirements.md' '$CMD_DIR/spec-requirements.md'"
assert "spec-design.md references specs/design.md" "grep -q 'specs/design.md' '$CMD_DIR/spec-design.md'"
assert "spec-tasks.md references specs/tasks.md" "grep -q 'specs/tasks.md' '$CMD_DIR/spec-tasks.md'"
assert "implement-task.md references specs/tasks.md" "grep -q 'specs/tasks.md' '$CMD_DIR/implement-task.md'"
assert "review.md references specs/requirements.md" "grep -q 'specs/requirements.md' '$CMD_DIR/review.md'"

# --- Task 7: .gitignore generation ---

GITIGNORE="$WORKDIR/tree-project/.gitignore"

assert "creates .gitignore" "[ -f '$GITIGNORE' ]"
for pattern in '__pycache__/' '\*\.py\[cod\]' '\.eggs/' '\*\.egg-info/' 'dist/' 'build/' '\.venv/' '^venv/$' '\.pytest_cache/' '\.mypy_cache/' '\.DS_Store'; do
    assert ".gitignore contains $pattern" "grep -q -- '$pattern' '$GITIGNORE'"
done

# --- Task 8: success reporting ---

run_in_workdir $'report-project\nreport_module\n'; STATUS=$?
assert "success report exits 0" "[ $STATUS -eq 0 ]"
assert "success message printed" "echo \"\$OUTPUT\" | grep -q \"Project 'report-project' created successfully\""
assert "directory structure listed (project root)" "echo \"\$OUTPUT\" | grep -q 'report-project'"
assert "directory structure listed (module dir)" "echo \"\$OUTPUT\" | grep -q 'report_module'"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All tests passed."
    exit 0
else
    echo "$FAILURES test(s) failed."
    exit 1
fi
