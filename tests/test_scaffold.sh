#!/bin/bash
# Lightweight test harness for new-sdd-project.sh (no external test framework required).
# Extended as each task in specs/load-template/tasks.md is implemented.

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

# Fixture template repo stands in for the real GitHub template so the suite
# runs offline/deterministically (specs/load-template/design.md § Testing
# Strategy).
FIXTURE_DIR=$(mktemp -d)
"$SCRIPT_DIR/tests/fixtures/build_template_fixture.sh" "$FIXTURE_DIR/template"
export SDD_TEMPLATE_URL="$FIXTURE_DIR/template"

# --- Task 1: shebang and input prompting ---

assert "new-sdd-project.sh exists" "[ -f '$SCAFFOLD' ]"
assert "new-sdd-project.sh is executable" "[ -x '$SCAFFOLD' ]"
assert "new-sdd-project.sh has a bash shebang" "head -n1 '$SCAFFOLD' | grep -q '^#!/bin/bash$'"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR" "$FIXTURE_DIR"' EXIT

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
assert "new-sdd-project.sh prompts for module name" "echo \"\$OUTPUT\" | grep -q 'Enter Python module name'"

# --- Task 2: input validation ---

# Empty project name
run_in_workdir $'\nmodule\n'; STATUS=$?
assert "empty project name exits non-zero" "[ $STATUS -ne 0 ]"
assert "empty project name prints error" "echo \"\$OUTPUT\" | grep -qi 'project name cannot be empty'"

# --- Task 37/38: module name suggestion ---

# Empty module name input accepts the suggested default (Requirement 11)
run_in_workdir $'BasicTest\n\n'; STATUS=$?
assert "empty module name input exits 0 (accepts suggestion)" "[ $STATUS -eq 0 ]"
assert "module name prompt shows bracketed suggestion" "echo \"\$OUTPUT\" | grep -q 'Enter Python module name \[basic_test\]:'"
assert "empty module name input resolves to suggested module name" "[ -d '$WORKDIR/BasicTest/src/basic_test' ]"

# Non-empty module name input overrides the suggestion
run_in_workdir $'HTTPServer\ncustom_name\n'; STATUS=$?
assert "typed module name override exits 0" "[ $STATUS -eq 0 ]"
assert "typed module name override is used verbatim" "[ -d '$WORKDIR/HTTPServer/src/custom_name' ]"
assert "typed module name override does not use the suggestion" "[ ! -d '$WORKDIR/HTTPServer/src/http_server' ]"

# Degenerate project names still produce a valid suggestion
run_in_workdir $'123\n\n'; STATUS=$?
assert "digit-leading project name exits 0" "[ $STATUS -eq 0 ]"
assert "digit-leading project name suggestion is prefixed with underscore" "[ -d '$WORKDIR/123/src/_123' ]"

run_in_workdir $'...\n\n'; STATUS=$?
assert "symbol-only project name exits 0" "[ $STATUS -eq 0 ]"
assert "symbol-only project name falls back to _module" "[ -d '$WORKDIR/.../src/_module' ]"

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

# --- Story 3: template-based scaffolding (directory creation) ---

run_in_workdir $'tree-project\ntree_module\n'; STATUS=$?
assert "directory creation exits 0" "[ $STATUS -eq 0 ]"
assert "creates Project_Root" "[ -d '$WORKDIR/tree-project' ]"
assert "creates src/{module}/ directory" "[ -d '$WORKDIR/tree-project/src/tree_module' ]"

# --- Story 3: placeholder package rename ---

assert "renames placeholder package to typed module name" "[ -d '$WORKDIR/tree-project/src/tree_module' ]"
assert "no leftover src/python_module after rename" "[ ! -d '$WORKDIR/tree-project/src/python_module' ]"
assert "creates src/{module}/__init__.py" "[ -f '$WORKDIR/tree-project/src/tree_module/__init__.py' ]"

run_in_workdir $'BasicTest\n\n'; STATUS=$?
assert "renames placeholder package to suggested module name" "[ -d '$WORKDIR/BasicTest/src/basic_test' ]"
assert "no leftover src/python_module after suggested rename" "[ ! -d '$WORKDIR/BasicTest/src/python_module' ]"

# --- Story 3: template content lands verbatim (not script-generated) ---

assert "tests/ contents match the fixture verbatim" "diff -qr '$FIXTURE_DIR/template/tests' '$WORKDIR/tree-project/tests' >/dev/null 2>&1"
assert ".claude/skills/ contents match the fixture verbatim" "diff -qr '$FIXTURE_DIR/template/.claude/skills' '$WORKDIR/tree-project/.claude/skills' >/dev/null 2>&1"
assert ".gitignore matches the fixture verbatim" "diff -q '$FIXTURE_DIR/template/.gitignore' '$WORKDIR/tree-project/.gitignore' >/dev/null 2>&1"

# --- Story 3: pyproject.toml generation (the one script-generated file) ---

PYPROJECT="$WORKDIR/tree-project/pyproject.toml"

assert "creates pyproject.toml" "[ -f '$PYPROJECT' ]"
assert "pyproject.toml declares project name" "grep -q 'name = \"tree-project\"' '$PYPROJECT'"
assert "pyproject.toml declares pytest as a dev dependency" "grep -q 'dev = \[\"pytest\"\]' '$PYPROJECT'"
assert "pyproject.toml registers the smoke marker" "grep -q 'smoke: marks a test as a smoke test' '$PYPROJECT'"
assert "pyproject.toml overwrites the template's own copy" "! grep -q 'placeholder-should-be-overwritten' '$PYPROJECT'"

# --- Story 3: README.md generation (the other script-generated file) ---

README="$WORKDIR/tree-project/README.md"

assert "creates README.md" "[ -f '$README' ]"
assert "README.md heading contains project name" "grep -q '^# tree-project$' '$README'"
assert "README.md overwrites the template's own copy" "! grep -q 'placeholder-should-be-overwritten' '$README'"

# --- Task 21: git init stage ---

if command -v git >/dev/null 2>&1; then
    GIT_PROJECT="$WORKDIR/tree-project"
    assert "creates .git/ directory" "[ -d '$GIT_PROJECT/.git' ]"
    assert "exactly one commit exists" "[ \"\$(cd '$GIT_PROJECT' && git log --oneline | wc -l | tr -d ' ')\" = '1' ]"
    assert "commit message is 'Create initial project'" "(cd '$GIT_PROJECT' && git log -1 --pretty=%s) | grep -q '^Create initial project$'"
    assert "working tree is clean after commit" "[ -z \"\$(cd '$GIT_PROJECT' && git status --porcelain)\" ]"
else
    echo "SKIPPED: git init assertions (git not found on PATH)"
fi

# --- Task 8: success reporting ---

run_in_workdir $'report-project\nreport_module\n'; STATUS=$?
assert "success report exits 0" "[ $STATUS -eq 0 ]"
assert "success message printed" "echo \"\$OUTPUT\" | grep -q \"Project 'report-project' created successfully\""
assert "directory structure listed (project root)" "echo \"\$OUTPUT\" | grep -q 'report-project'"
assert "directory structure listed (module dir)" "echo \"\$OUTPUT\" | grep -q 'report_module'"

# --- Task 25: .git/ excluded from directory structure output ---

if command -v git >/dev/null 2>&1; then
    assert "directory structure excludes .git" "! echo \"\$OUTPUT\" | grep -qE '\.git(\$|[^a-zA-Z])'"
else
    echo "SKIPPED: .git exclusion assertion (git not found on PATH)"
fi

# --- Story 4: missing git is a hard failure before any clone attempt ---

NO_GIT_BIN="$WORKDIR/.no_git_bin"
mkdir -p "$NO_GIT_BIN"
for tool in mkdir touch cat find sed mv rm mktemp; do
    tool_path=$(command -v "$tool" 2>/dev/null)
    if [ -n "$tool_path" ]; then
        ln -sf "$tool_path" "$NO_GIT_BIN/$tool"
    fi
done

NO_GIT_CAPTURE="$WORKDIR/.no_git_out"
(cd "$WORKDIR" && printf '%s' $'no-git-project\nno_git_module\n' | env PATH="$NO_GIT_BIN" SDD_TEMPLATE_URL="$SDD_TEMPLATE_URL" "$SCAFFOLD" >"$NO_GIT_CAPTURE" 2>&1)
NO_GIT_STATUS=$?
NO_GIT_OUTPUT=$(cat "$NO_GIT_CAPTURE" 2>/dev/null)
rm -f "$NO_GIT_CAPTURE"

assert "missing git exits non-zero" "[ $NO_GIT_STATUS -ne 0 ]"
assert "missing git prints error" "echo \"\$NO_GIT_OUTPUT\" | grep -qi 'git.*not found'"
assert "missing git creates no Project_Root" "[ ! -e '$WORKDIR/no-git-project' ]"

# --- Story 4: clone failure leaves no partially-created Project_Root ---

CLONE_FAIL_CAPTURE="$WORKDIR/.clone_fail_out"
(cd "$WORKDIR" && printf '%s' $'clone-fail-project\nclone_fail_module\n' | env SDD_TEMPLATE_URL="$WORKDIR/.nonexistent-template" "$SCAFFOLD" >"$CLONE_FAIL_CAPTURE" 2>&1)
CLONE_FAIL_STATUS=$?
CLONE_FAIL_OUTPUT=$(cat "$CLONE_FAIL_CAPTURE" 2>/dev/null)
rm -f "$CLONE_FAIL_CAPTURE"

assert "clone failure exits non-zero" "[ $CLONE_FAIL_STATUS -ne 0 ]"
assert "clone failure prints error" "echo \"\$CLONE_FAIL_OUTPUT\" | grep -qi 'failed to clone'"
assert "clone failure creates no Project_Root" "[ ! -e '$WORKDIR/clone-fail-project' ]"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All tests passed."
    exit 0
else
    echo "$FAILURES test(s) failed."
    exit 1
fi
