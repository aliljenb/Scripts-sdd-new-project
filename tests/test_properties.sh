#!/bin/bash
# Property-based tests for new-sdd-project.sh, mapped to the 13 correctness
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
        ".claude/CLAUDE.md"
        ".gitignore"
    )
    for p in "${required_paths[@]}"; do
        assert "Property 2: $proj contains $p" "[ -f '$root/$p' ]"
    done
done
echo "Property 2 (complete directory structure invariant): done"

# --- Property 3: .gitignore content completeness ---
patterns=('__pycache__/' '\*\.py\[cod\]' '\.eggs/' '\*\.egg-info/' 'dist/' 'build/' '\.venv/' '^venv/$' '\.pytest_cache/' '\.mypy_cache/' '\.DS_Store' '\.idea/' \
    '\*\.class' 'target/' 'node_modules/' '\.next/' '\.vercel' '^\.env$' '\*\.iml' '\.vscode/\*' '\.Spotlight-V100' '\*\.log')
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
# random_invalid_module_name() always returns a non-empty string (leading
# digit / hyphen / space / dot variants), so empty input is never exercised
# here as a rejection case — empty input now accepts the suggested default
# (Requirement 11), not an error.
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p4-$(random_valid_project_name)-$i"
    mod=$(random_invalid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    assert "Property 4: exit non-zero for invalid module '$mod'" "[ $STATUS -ne 0 ]"
    assert "Property 4: no directory created for '$proj'" "[ ! -d '$WORKDIR/$proj' ]"
done
echo "Property 4 (invalid module name rejection): done"

# --- Property 5: Empty project name rejection ---
# An empty module name is no longer a rejection case as of Requirement 11 —
# it resolves to the Suggested_Module_Name instead (see Property 16).
for ((i = 0; i < ITERATIONS; i++)); do
    mod=$(random_valid_module_name)

    # Empty project name
    run_scaffold "$WORKDIR" ""$'\n'"$mod"$'\n'
    assert "Property 5: exit non-zero for empty project name" "[ $STATUS -ne 0 ]"
done
echo "Property 5 (empty project name rejection): done"

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
    if command -v git >/dev/null 2>&1; then
        assert "Property 7: stdout for '$proj' excludes .git" "! echo \"\$OUTPUT\" | grep -qE '\.git(\$|[^a-zA-Z])'"
    fi
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

# --- Property 13: design.md template source-layout note ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p13-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    design_md="$WORKDIR/$proj/specs/design.md"
    assert "Property 13: $proj design.md has Source Layout Constraint heading" "grep -q '^## Source Layout Constraint$' '$design_md'"
    assert "Property 13: $proj design.md note references src/$mod/" "grep -q \"src/$mod/\" '$design_md'"
done
echo "Property 13 (design.md template source-layout note): done"

# --- Property 11: Git repository initialization completeness ---
GIT_IDENTITY_OK=0
if command -v git >/dev/null 2>&1; then
    ID_CHECK_DIR=$(mktemp -d)
    if (cd "$ID_CHECK_DIR" && git init -q && touch f && git add f && git commit -q -m "identity check") >/dev/null 2>&1; then
        GIT_IDENTITY_OK=1
    fi
    rm -rf "$ID_CHECK_DIR"
fi

if [ "$GIT_IDENTITY_OK" = "1" ]; then
    for ((i = 0; i < ITERATIONS; i++)); do
        proj="p11-$(random_valid_project_name)-$i"
        mod=$(random_valid_module_name)
        run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
        root="$WORKDIR/$proj"
        assert "Property 11: $proj .git/ exists" "[ -d '$root/.git' ]"
        assert "Property 11: $proj exactly one commit" "[ \"\$(cd '$root' && git log --oneline | wc -l | tr -d ' ')\" = '1' ]"
        assert "Property 11: $proj commit message correct" "(cd '$root' && git log -1 --pretty=%s) | grep -q '^Create initial project$'"
        assert "Property 11: $proj working tree clean" "[ -z \"\$(cd '$root' && git status --porcelain)\" ]"
        tracked_files=$(cd "$root" && git ls-tree -r --name-only HEAD)
        required_tracked_paths=(
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
            ".claude/CLAUDE.md"
            ".gitignore"
        )
        for p in "${required_tracked_paths[@]}"; do
            assert "Property 11: $proj commit tracks $p" "echo \"\$tracked_files\" | grep -qx \"$p\""
        done
    done
    echo "Property 11 (git repository initialization completeness): done"
else
    echo "Property 11 (git repository initialization completeness): SKIPPED (git unavailable or no identity configured)"
fi

# --- Property 12: Graceful degradation without git ---
FAKE_BIN="$WORKDIR/.fake_bin_no_git"
mkdir -p "$FAKE_BIN"
for tool in mkdir touch cat find sed; do
    tool_path=$(command -v "$tool" 2>/dev/null)
    if [ -n "$tool_path" ]; then
        ln -sf "$tool_path" "$FAKE_BIN/$tool"
    fi
done

for ((i = 0; i < ITERATIONS; i++)); do
    proj="p12-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    capture="$WORKDIR/.scaffold_out_p12"
    (cd "$WORKDIR" && printf '%s' "$proj"$'\n'"$mod"$'\n' | env PATH="$FAKE_BIN" "$SCAFFOLD" >"$capture" 2>&1)
    STATUS=$?
    OUTPUT=$(cat "$capture" 2>/dev/null)
    rm -f "$capture"
    root="$WORKDIR/$proj"
    assert "Property 12: $proj exits 0 without git" "[ $STATUS -eq 0 ]"
    assert "Property 12: $proj prints git warning" "echo \"\$OUTPUT\" | grep -qi 'git not found'"
    assert "Property 12: $proj creates full file structure" "[ -f '$root/src/$mod/__init__.py' ] && [ -f '$root/pyproject.toml' ] && [ -f '$root/.gitignore' ]"
    assert "Property 12: $proj creates no .git directory" "[ ! -d '$root/.git' ]"
done
echo "Property 12 (graceful degradation without git): done"

# --- Property 14: implement-task.md all-at-once-vs-one-by-one gate content ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p14-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    cmd_file="$WORKDIR/$proj/.claude/commands/implement-task.md"
    assert "Property 14: $proj implement-task.md has gate heading" "grep -q '^## Before implementing$' '$cmd_file'"
    assert "Property 14: $proj implement-task.md mentions AskUserQuestion tool" "grep -q 'AskUserQuestion' '$cmd_file'"
    assert "Property 14: $proj implement-task.md mentions skipping the question for one remaining task" "grep -q 'exactly one unchecked task remains' '$cmd_file'"
    assert "Property 14: $proj implement-task.md mentions stopping on error without continuing" "grep -q 'stop immediately' '$cmd_file'"
done
echo "Property 14 (implement-task.md all-at-once-vs-one-by-one gate content): done"

# --- Property 15: CLAUDE.md agent-loop hygiene content completeness ---
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p15-$(random_valid_project_name)-$i"
    mod=$(random_valid_module_name)
    run_scaffold "$WORKDIR" "$proj"$'\n'"$mod"$'\n'
    claude_md="$WORKDIR/$proj/.claude/CLAUDE.md"
    assert "Property 15: $proj CLAUDE.md has agent-loop hygiene heading" "grep -q '^## Agent-loop and internal-message hygiene$' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions prompt injection pattern example" "grep -qF '\"prompt injection pattern\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions stale scheduled check example" "grep -qF '\"stale scheduled check\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions loop wakeup example" "grep -qF '\"Claude resuming /loop wakeup\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions internal scheduling prompt example" "grep -qF '\"internal scheduling prompt\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions task monitor example" "grep -qF '\"task monitor\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions already delivered example" "grep -qF '\"already delivered in my last message\"' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions explicit-request exception" "grep -q 'unless the user explicitly asks' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions non-authoritative stale prompts" "grep -q 'non-authoritative' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions not restarting completed work" "grep -q 'Do not restart completed work' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md lists the five completion-report items" "grep -q 'whether anything remains to be done' '$claude_md'"
    assert "Property 15: $proj CLAUDE.md mentions never exposing internal reasoning" "grep -q 'Never expose internal reasoning' '$claude_md'"
done
echo "Property 15 (CLAUDE.md agent-loop hygiene content completeness): done"

# --- Property 16: Suggested module name computation and default acceptance ---

# Fixed Examples table from Requirement 11 (camelCase/acronym/digit-prefix/
# empty-fallback edge cases are unlikely to be hit by random generation, so
# they're checked against known inputs rather than randomized ones).
P16_FIXED_DIR="$WORKDIR/.p16fixed"
mkdir -p "$P16_FIXED_DIR"
P16_EXAMPLES=(
    "BasicTest:basic_test"
    "basic-test:basic_test"
    "basic_test:basic_test"
    "HTTPServer:http_server"
    "MyIOTool:my_io_tool"
    "123:_123"
    "...:_module"
    "_9lives:_9lives"
)
for pair in "${P16_EXAMPLES[@]}"; do
    proj="${pair%%:*}"
    expected="${pair##*:}"
    run_scaffold "$P16_FIXED_DIR" "$proj"$'\n\n'
    assert "Property 16: $proj exits 0 accepting the suggestion" "[ $STATUS -eq 0 ]"
    assert "Property 16: $proj prompt shows suggestion [$expected]" "echo \"\$OUTPUT\" | grep -qF \"Enter Python module name [$expected]:\""
    assert "Property 16: $proj resolves to suggested module name $expected" "[ -d '$P16_FIXED_DIR/$proj/src/$expected' ]"
    rm -rf "${P16_FIXED_DIR:?}/${proj:?}"
done
echo "Property 16 (fixed examples table): done"

# Randomized: accepted default is always a valid Python identifier, is
# deterministic for a given project name, and a typed override is honored.
for ((i = 0; i < ITERATIONS; i++)); do
    proj="p16-$(random_valid_project_name)-$i"
    dir_a="$WORKDIR/.p16a"
    dir_b="$WORKDIR/.p16b"
    mkdir -p "$dir_a" "$dir_b"

    run_scaffold "$dir_a" "$proj"$'\n\n'
    assert "Property 16: $proj (run A) exits 0" "[ $STATUS -eq 0 ]"
    suggestion_a=$(find "$dir_a/$proj/src" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n1 basename 2>/dev/null)

    run_scaffold "$dir_b" "$proj"$'\n\n'
    assert "Property 16: $proj (run B) exits 0" "[ $STATUS -eq 0 ]"
    suggestion_b=$(find "$dir_b/$proj/src" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n1 basename 2>/dev/null)

    assert "Property 16: $proj suggestion '$suggestion_a' is a valid Python identifier" "printf '%s' '$suggestion_a' | grep -Eq '^[a-zA-Z_][a-zA-Z0-9_]*$'"
    assert "Property 16: $proj suggestion is deterministic ('$suggestion_a' == '$suggestion_b')" "[ \"$suggestion_a\" = \"$suggestion_b\" ]"

    rm -rf "$dir_a" "$dir_b"

    override="ov_$(random_valid_module_name)"
    run_scaffold "$WORKDIR" "$proj"$'\n'"$override"$'\n'
    assert "Property 16: $proj typed override '$override' used verbatim" "[ -d '$WORKDIR/$proj/src/$override' ]"
    rm -rf "${WORKDIR:?}/${proj:?}"
done
echo "Property 16 (suggested module name computation and default acceptance): done"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All property-based tests passed."
    exit 0
else
    echo "$FAILURES property assertion(s) failed."
    exit 1
fi
