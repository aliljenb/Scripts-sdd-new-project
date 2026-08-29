#!/bin/bash

# Sanitizes a project name into a valid Python identifier suggestion for the
# module name prompt. See specs/load-template/design.md's Pipeline step 2.
sanitize_module_name() {
    local input="$1"
    local result

    # (a) camelCase word boundaries: lower/digit -> Upper, then a run of
    #     2+ uppercase letters followed by Upper+lower (keeps acronym runs
    #     like "HTTP" in "HTTPServer" together as one segment)
    result=$(printf '%s' "$input" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g; s/([A-Z]+)([A-Z][a-z])/\1_\2/g')

    # (b) anything that isn't a letter, digit, or underscore -> underscore
    result=$(printf '%s' "$result" | sed -E 's/[^a-zA-Z0-9_]/_/g')

    # (c) collapse repeated underscores
    result=$(printf '%s' "$result" | sed -E 's/_+/_/g')

    # (d) lowercase (tr, not ${var,,} — macOS ships bash 3.2, which lacks
    #     bash 4's case-conversion parameter expansion)
    result=$(printf '%s' "$result" | tr 'A-Z' 'a-z')

    # (e) strip a trailing underscore produced by (a)-(c) unconditionally,
    #     and a leading one unless the original input itself started with '_'
    result=$(printf '%s' "$result" | sed -E 's/_+$//')
    if [[ "$input" != _* ]]; then
        result=$(printf '%s' "$result" | sed -E 's/^_+//')
    fi

    # empty sanitized result -> fixed fallback
    if [ -z "$result" ]; then
        result="_module"
    fi

    # sanitized result starts with a digit -> prefix underscore
    if [[ "$result" =~ ^[0-9] ]]; then
        result="_${result}"
    fi

    printf '%s' "$result"
}

# Prompts for and returns the project name. The prompt text goes to stderr
# so it isn't captured by callers using command substitution.
prompt_project_name() {
    echo "Enter project name:" >&2
    local name
    read -r name
    printf '%s' "$name"
}

# Rejects an empty project name or one that would corrupt later path
# handling (a path separator, or a leading '-' that could be read as a flag).
validate_project_name() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Error: Project name cannot be empty." >&2
        return 1
    fi
    if [[ "$name" == */* ]] || [[ "$name" == -* ]]; then
        echo "Error: Project name must not contain '/' or start with '-'." >&2
        return 1
    fi
    return 0
}

# Prompts for the module name, showing $1 as the default; empty input
# resolves to that default.
prompt_module_name() {
    local suggested="$1"
    echo "Enter Python module name [$suggested]:" >&2
    local input
    read -r input
    if [ -z "$input" ]; then
        printf '%s' "$suggested"
    else
        printf '%s' "$input"
    fi
}

# Rejects a module name that isn't a valid Python identifier.
validate_module_name() {
    local name="$1"
    if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Error: Module name must be a valid Python identifier." >&2
        return 1
    fi
    return 0
}

# Rejects a project name for which a file/directory already exists.
check_project_root_available() {
    local name="$1"
    if [ -e "$name" ]; then
        echo "Error: '$name' already exists." >&2
        return 1
    fi
    return 0
}

# Rejects if the git binary isn't on PATH. Checked before any clone is
# attempted, since git is now required for cloning, not just the final
# commit.
check_git_available() {
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required but was not found on PATH." >&2
        return 1
    fi
    return 0
}

# Clones the Template_Repository into $1 (a pre-created, empty staging
# directory). SDD_TEMPLATE_URL overrides the URL for test isolation only —
# see specs/load-template/design.md's "Template URL resolution" section.
# On failure, removes the staging directory and returns non-zero without
# ever touching the real Project_Root path.
clone_template() {
    local staging_dir="$1"
    local template_url="${SDD_TEMPLATE_URL:-https://github.com/aliljenb/Scripts-sdd-template.git}"
    if ! git clone -q "$template_url" "$staging_dir" >/dev/null 2>&1; then
        echo "Error: failed to clone template repository from '$template_url'." >&2
        rm -rf "$staging_dir"
        return 1
    fi
    return 0
}

# Renames the cloned placeholder package (src/python_module/) to the
# resolved module name.
rename_placeholder_package() {
    local staging_dir="$1" module_name="$2"
    mv "$staging_dir/src/python_module" "$staging_dir/src/$module_name"
}

# Generates pyproject.toml with the project name baked in, overwriting
# any pyproject.toml the template shipped — the one file the script still
# generates itself, since it needs the actual project name.
generate_pyproject() {
    local staging_dir="$1" project_name="$2"
    cat > "$staging_dir/pyproject.toml" << EOF
[project]
name = "$project_name"
version = "0.1.0"

[project.optional-dependencies]
dev = ["pytest"]

[tool.pytest.ini_options]
markers = [
    "smoke: marks a test as a smoke test",
]
EOF
}

# Generates README.md with the project name baked in, overwriting any
# README.md the template shipped — deliberately script-authored instead of
# using the template's own copy.
generate_readme() {
    local staging_dir="$1" project_name="$2"
    cat > "$staging_dir/README.md" << EOF
# $project_name

A new project scaffolded from the SDD template.
EOF
}

# Strips any cloned .git history/remote and re-initializes a fresh local
# repo with its own initial commit. Mirrors the prior implementation's
# soft-failure handling: a missing git binary is now a hard failure earlier
# (check_git_available), but an init/commit failure here (e.g. no git
# identity configured) is reported as a warning rather than aborting.
finalize_git_repo() {
    local project_root="$1"
    rm -rf "$project_root/.git"
    if ! (cd "$project_root" && git init -q && git add -A && git commit -q -m "Create initial project") >/dev/null 2>&1; then
        echo "Warning: git initialization or commit failed; skipping repository setup." >&2
    fi
}

# Reports success and prints the resulting directory tree, excluding .git.
report_success() {
    local project_root="$1"
    echo ""
    echo "Project '$project_root' created successfully!"
    echo ""
    echo "Directory structure:"
    find "$project_root" -path "$project_root/.git" -prune -o -print | sed -e "s;[^/]*/;  ;g;s;  \([^ ]\);├─ \1;"
}

main() {
    local project_name module_name suggested_module_name staging_dir

    project_name=$(prompt_project_name)
    validate_project_name "$project_name" || exit 1

    suggested_module_name=$(sanitize_module_name "$project_name")

    module_name=$(prompt_module_name "$suggested_module_name")
    validate_module_name "$module_name" || exit 1

    check_project_root_available "$project_name" || exit 1
    check_git_available || exit 1

    staging_dir=$(mktemp -d)

    clone_template "$staging_dir" || exit 1

    rename_placeholder_package "$staging_dir" "$module_name"
    generate_pyproject "$staging_dir" "$project_name"
    generate_readme "$staging_dir" "$project_name"

    mv "$staging_dir" "$project_name"

    finalize_git_repo "$project_name"

    report_success "$project_name"
}

main "$@"
