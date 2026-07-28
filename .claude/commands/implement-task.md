Read the files `specs/tasks.md` and `specs/design.md` and implement the next unchecked task.

## Before implementing

Count the unchecked tasks (marked with `- [ ]`) in `specs/tasks.md`.
- IF more than one unchecked task remains, ask the user whether to implement
  all remaining unchecked tasks at once or one at a time. Use the
  `AskUserQuestion` tool so the choice is clickable, falling back to a
  lettered list in chat if that tool is unavailable.
- IF exactly one unchecked task remains, skip this question and implement
  it directly.

Follow these guidelines:
- Find the first unchecked task (marked with `- [ ]`) in `specs/tasks.md`
- Read the design document for implementation guidance
- Write the code to implement the task
- Write tests for the implementation
- Mark the task as complete (change `- [ ]` to `- [x]`) in `specs/tasks.md`

After implementation, run the tests to verify correctness.

If the user chose "all at once", repeat this process for each remaining
unchecked task in order. If an error or test failure occurs while
implementing any task, stop immediately, leave that task and all
subsequent tasks unchecked, and report the failure to the user rather
than continuing to later tasks.
