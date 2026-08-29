#!/bin/bash
# Builds a local git repository fixture that stands in for
# https://github.com/aliljenb/Scripts-sdd-template.git in tests, so the
# test suite can run offline and deterministically. Point new-sdd-project.sh
# at the built fixture via SDD_TEMPLATE_URL (see specs/load-template/design.md
# § Template URL resolution).
#
# Usage: build_template_fixture.sh <target-dir>

set -eu

TARGET_DIR="$1"

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR/src/python_module"
mkdir -p "$TARGET_DIR/tests"
mkdir -p "$TARGET_DIR/.claude/skills/spec-requirements"

touch "$TARGET_DIR/src/python_module/__init__.py"
touch "$TARGET_DIR/tests/__init__.py"

cat > "$TARGET_DIR/tests/test_python_module.py" << 'EOF'
import pytest


@pytest.mark.smoke
def test_placeholder():
    assert True
EOF

cat > "$TARGET_DIR/.claude/skills/spec-requirements/SKILL.md" << 'EOF'
# Fixture spec-requirements skill

Stands in for the real template's skill content in tests.
EOF

cat > "$TARGET_DIR/.gitignore" << 'EOF'
__pycache__/
*.py[cod]
.venv/
# fixture-marker
EOF

# Deliberately present so tests can assert generate_pyproject() overwrites
# it rather than leaving the template's own copy in place.
cat > "$TARGET_DIR/pyproject.toml" << 'EOF'
[project]
name = "placeholder-should-be-overwritten"
EOF

# Deliberately present so tests can assert generate_readme() overwrites it
# rather than leaving the template's own copy in place.
cat > "$TARGET_DIR/README.md" << 'EOF'
# placeholder-should-be-overwritten
EOF

git -C "$TARGET_DIR" init -q
git -C "$TARGET_DIR" add -A
git -C "$TARGET_DIR" \
    -c user.email="fixture@example.com" \
    -c user.name="Fixture" \
    commit -q -m "Fixture template"
