# Implementation Notes: load-template

## Deviation: test file is not renamed to match the module name

`requirements.md`'s Glossary describes `Test_Package` as containing "a
placeholder `test_<Python_Package>.py` file", implying the test filename
tracks the user's chosen module name. That wording was carried over from
the prior heredoc-based implementation and was never updated when Story 3
was added.

Story 3's actual acceptance criteria only specify renaming the
Placeholder_Package **directory** (`src/python_module/` →
`src/<module_name>/`) — nothing in Story 3 or design.md's Pipeline/Function
sections calls for renaming the test file that ships in `tests/`.

Implementation follows Story 3's acceptance criteria (the operative
contract) rather than the stale Glossary phrasing: the template's test file
is cloned verbatim as `tests/test_python_module.py` regardless of the
resolved module name. `tests/test_scaffold.sh`'s assertions were written
against this behavior (verbatim `diff` against the fixture, no
module-name-specific filename check).

If the fixed filename turns out to be undesirable, requirements.md/design.md
should be revised to add an explicit rename step before the tasks.md/test
assumptions are changed to match.

## Deviation: tasks.md's test_properties.sh task was under-specified

The single tasks.md bullet for `tests/test_properties.sh` ("update to
export SDD_TEMPLATE_URL ... keeping its existing generators") understated
the file's actual scope: 10 of its 16 randomized properties (2, 3, 8, 9
partly, 10 partly, 12, 13, 14, 15) asserted specific content the script
used to generate itself (`.claude/commands/*`, `CLAUDE.md` text,
`.gitignore` patterns, `specs/design.md` headings) — content that no longer
exists once that generation moved to the template.

Flagged to the user before proceeding; approved approach: rewrite the file
wholesale using the same categories design.md's Testing Strategy already
specifies for `test_scaffold.sh` (fixture-verbatim `diff` checks in place of
literal content assertions), keep the properties that test prompting/
validation/naming (1, 4, 5, 6, 7, 16) and git init/commit (11, adapted),
rewrite Property 12 from "graceful degradation without git" to "missing git
is a hard failure" (Story 4 reversed this behavior), and add Properties 17
(placeholder rename) and 18 (clone-failure leaves no partial directory).
