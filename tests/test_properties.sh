#!/bin/bash
# Property-based tests for new-sdd-project.sh, mapped to the 10 correctness
# properties defined in specs/design.md. Each property is checked against
# a batch of randomly generated inputs rather than a single fixed example.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAFFOLD="$SCRIPT_DIR/new-sdd-project.sh"
FAILURES=0
ITERATIONS="${ITERATIONS:-20}"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

assert() {
    local description="$1"
    local condition="$2"
    if eval "$condition"; then
        return 0
    else
        echo "FAIL: $description"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

run_scaffold() {
    # run_scaffold <dir> <stdin-string>
    local dir="$1" stdin="$2"
    local capture="$dir/.scaffold_out"
    (cd "$dir" && printf '%s' "$stdin" | "$SCAFFOLD" >"$capture" 2>&1)
    STATUS=$?
    OUTPUT=$(cat "$capture" 2>/dev/null)
    rm -f "$capture"
    return $STATUS
}

random_word() {
    # random_word <alphabet> <min_len> <max_len>
    local alphabet="$1" min="$2" max="$3"
    local len=$((RANDOM % (max - min + 1) + min))
    local word=""
    local i
    for ((i = 0; i < len; i++)); do
        word="${word}${alphabet:$((RANDOM % ${#alphabet})):1}"
    done
    echo "$word"
}

random_valid_module_name() {
    # ^[a-zA-Z_][a-zA-Z0-9_]*$
    local first
    first=$(random_word "abcdefghijklmnopqrstuvwxyz_" 1 1)
    local rest
    rest=$(random_word "abcdefghijklmnopqrstuvwxyz0123456789_" 2 10)
    echo "${first}${rest}"
}

random_valid_project_name() {
    random_word "abcdefghijklmnopqrstuvwxyz0123456789-_" 3 12
}

random_invalid_module_name() {
    # Guaranteed to violate ^[a-zA-Z_][a-zA-Z0-9_]*$
    local variants=(
        "$(random_word "0123456789" 1 4)$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5)"  # leading digit
        "$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5)-$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5)"  # hyphen
        "$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5) $(random_word "abcdefghijklmnopqrstuvwxyz" 2 5)"  # space
        "$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5).$(random_word "abcdefghijklmnopqrstuvwxyz" 2 5)"  # dot
    )
    echo "${variants[$((RANDOM % ${#variants[@]}))]}"
}

echo "Running property-based tests ($ITERATIONS iterations per property)..."

# --- Property 1: Input-to-directory-name fidelity ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p1-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    assert "Property 1: exit 0 for $proj/$mod" "[ $STATUS -eq 0 ]"
    assert "Property 1: dir named exactly '$proj' exists" "[ -d '$WORKDIR/$proj' ]"
    assert "Property 1: src/$mod/ exists under '$proj'" "[ -d '$WORKDIR/$proj/src/$mod' ]"
done
echo "Property 1 (input-to-directory-name fidelity): done"

# --- Property 2: Complete directory structure invariant ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p2-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    root="$WORKDIR/$proj"
    required_paths=(
        "src/$mod/__init__.py"
        "tests/__init__.py"
        "tests/test_$mod.py"
        "pyproject.toml"
        "specs/requirements.md"
        "specs/design.md"
        "specs/tasks.md"
        ".claude/commands/spec-requirements.md"
        ".claude/commands/spec-design.md"
        ".claude/commands/spec-tasks.md"
        ".claude/commands/implement-task.md"
        ".claude/commands/review.md"
        ".gitignore"
    )
    for p in "${required_paths[@]}"; do
        assert "Property 2: $proj contains $p" "[ -f '$root/$p' ]"
    done
done
echo "Property 2 (complete directory structure invariant): done"

# --- Property 3: .gitignore content completeness ---
patterns=('__pycache__/' '\*\.py\[cod\]' '\.eggs/' '\*\.egg-info/' 'dist/' 'build/' '\.venv/' '^venv/$' '\.pytest_cache/' '\.mypy_cache/' '\.DS_Store')
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p3-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    for pattern in "${patterns[@]}"; do
        assert "Property 3: $proj .gitignore contains $pattern" "grep -q -- '$pattern' '$WORKDIR/$proj/.gitignore'"
    done
done
echo "Property 3 (.gitignore content completeness): done"

# --- Property 4: Invalid module name rejection ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p4-$(random_valid_project_name)-$i"
    mod=$(random_invalid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    assert "Property 4: exit non-zero for invalid module '$mod'" "[ $STATUS -ne 0 ]"
    assert "Property 4: no directory created for '$proj'" "[ ! -d '$WORKDIR/$proj' ]"
done
echo "Property 4 (invalid module name rejection): done"

# --- Property 5: Empty input rejection ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p5-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)

    # Empty project name
    run_scaffold "$WORKDIR" ""$'\n'"$mod"$'\n'
    assert "Property 5: exit non-zero for empty project name" "[ $STATUS -ne 0 ]"

    # Empty module name
    run_scaffold "$WORKDIR" "$proj"$'\n'""$'\n'
    assert "Property 5: exit non-zero for empty module name" "[ $STATUS -ne 0 ]"
    assert "Property 5: no directory created for '$proj' (empty module)" "[ ! -d '$WORKDIR/$proj' ]"
done
echo "Property 5 (empty input rejection): done"

# --- Property 6: Pre-existing directory rejection ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p6-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    mkdir -p "$WORKDIR/$proj"
    echo "sentinel" > "$WORKDIR/$proj/marker.txt"
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    assert "Property 6: exit non-zero for pre-existing '$proj'" "[ $STATUS -ne 0 ]"
    assert "Property 6: existing directory left unmodified for '$proj'" "[ -f '$WORKDIR/$proj/marker.txt' ] && [ ! -d '$WORKDIR/$proj/src' ]"
done
echo "Property 6 (pre-existing directory rejection): done"

# --- Property 7: Success output contains structure ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p7-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    assert "Property 7: stdout contains success message for '$proj'" "echo \"\$OUTPUT\" | grep -q \"Project '$proj' created successfully\""
    assert "Property 7: stdout references '$proj' path" "echo \"\$OUTPUT\" | grep -q '$proj'"
    assert "Property 7: stdout references '$mod' path" "echo \"\$OUTPUT\" | grep -q '$mod'"
done
echo "Property 7 (success output contains structure): done"

# --- Property 8: spec-requirements.md control-question gate content ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p8-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    cmd_file="$WORKDIR/$proj/.claude/commands/spec-requirements.md"
    assert "Property 8: $proj spec-requirements.md has gate heading" "grep -q '^## Before writing or editing anything$' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions stopping to ask on ambiguity" "grep -q 'stop and ask control questions' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions one question at a time" "grep -q 'one question at a time' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions 2-4 mutually exclusive options" "grep -q '2-4 concrete, mutually exclusive' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions Other free text" "grep -qi '\"Other\" with free text' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions AskUserQuestion tool" "grep -q 'AskUserQuestion' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions A/B/C/D fallback" "grep -q 'A/B/C/D' '$cmd_file'"
    assert "Property 8: $proj spec-requirements.md mentions withholding edits until resolved" "grep -q 'blocking' '$cmd_file'"
done
echo "Property 8 (spec-requirements.md control-question gate content): done"

# --- Property 9: Test package validity ---
if command -v pytest >/dev/null 2>&1; then
    for ((i = 0; i < ITERATIONS; i++)); do
        proj="p9-$(random_valid_project_name)-$i"
        mod=$(random_valid_module_name)
        run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
        root="$WORKDIR/$proj"
        assert "Property 9: $proj tests/__init__.py exists" "[ -f '$root/tests/__init__.py' ]"
        assert "Property 9: $proj tests/test_$mod.py exists" "[ -f '$root/tests/test_$mod.py' ]"
        assert "Property 9: $proj tests/test_$mod.py defines a test_ function" "grep -q '^def test_' '$root/tests/test_$mod.py'"
        assert "Property 9: $proj tests/test_$mod.py imports pytest" "grep -q '^import pytest$' '$root/tests/test_$mod.py'"
        assert "Property 9: $proj tests/test_$mod.py decorated with @pytest.mark.smoke" "grep -q '^@pytest.mark.smoke$' '$root/tests/test_$mod.py'"
        (cd "$root" && pytest -q >/dev/null 2>&1)
        assert "Property 9: $proj pytest exits 0" "[ $? -eq 0 ]"
    done
    echo "Property 9 (test package validity): done"
else
    echo "Property 9 (test package validity): SKIPPED (pytest not found on PATH)"
fi

# --- Property 10: Project manifest completeness ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p10-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    pyproject="$WORKDIR/$proj/pyproject.toml"
    assert "Property 10: $proj pyproject.toml exists" "[ -f '$pyproject' ]"
    assert "Property 10: $proj pyproject.toml declares pytest dev dependency" "grep -q 'dev = \[\"pytest\"\]' '$pyproject'"
    assert "Property 10: $proj pyproject.toml registers smoke marker" "grep -q 'smoke: marks a test as a smoke test' '$pyproject'"
done
echo "Property 10 (project manifest completeness): done"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All property-based tests passed."
    exit 0
else
    echo "$FAILURES property assertion(s) failed."
    exit 1
fi
