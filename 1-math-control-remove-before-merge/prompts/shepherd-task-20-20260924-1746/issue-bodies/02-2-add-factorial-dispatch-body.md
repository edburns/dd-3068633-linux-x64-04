## Campaign context and required reading

**On the `experiment/shepherd-control` branch, the directory `1-math-control-remove-before-merge` contains the plan (`math-tool-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**

Read the entire plan before working. Then carefully re-read these exact sections:

- `## Ignorance reduction`
- `### Repository-owned validation`
- `### Output and ordering contracts`
- `## Implementation`
- `### 1. Implement Fibonacci with unit and isolated CLI coverage`
- `### 2. Add factorial and operation dispatch`

The resolved decisions that constrain this task are:

- Repository acceptance is defined by `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`. The baseline workflow `.github/workflows/shepherd-task-math-tool.yml` installs exactly Pester 5.7.1 and invokes that repository-owned runner. Do not replace, bypass, or duplicate the runner.
- Direct CLI execution must write exactly one result line to stdout: `Fibonacci(N) = value` or `Factorial(N) = value`, selected by the requested operation.
- Functions return only numeric values, with no incidental output.
- Inputs are non-negative integers.
- The production and test files remain the repository-root files `math-tool.ps1` and `math-tool.Tests.ps1`.
- Work is serial. This task depends on task 1 already being merged, and all Fibonacci behavior established there must remain intact.

Research established these operational findings: operation dispatch must preserve a clean separation between pure function return values and the single formatted direct-execution line, and CLI behavior must be verified in isolated child `pwsh` processes. The combined suite must catch regressions in the previously merged Fibonacci contract as well as new factorial behavior. Implement from the plan's findings; do not copy or adapt research code.

## Branch and execution order

Use `experiment/shepherd-control` from remote `origin` as the PR base branch. This is implementation subsection 2 and the second of two tasks.

The two tasks are assigned, completed, and merged serially in plan order. Do not start work until this issue is assigned and task 1 has been merged into `experiment/shepherd-control`. Begin from the updated base branch containing task 1.

Keep the PR limited to this issue and target `experiment/shepherd-control`.

## Implement

Extend repository-root `math-tool.ps1` while preserving the merged Fibonacci implementation:

- Add a pure `Get-Factorial` function that returns only the numeric factorial value.
- Add an `Operation` parameter that dispatches between `fibonacci` and `factorial` while retaining the existing `N` parameter.
- For direct execution, format exactly one stdout line using the selected operation: `Fibonacci(N) = value` or `Factorial(N) = value`.
- Implement factorial correctly for `N=0`, `N=1`, and larger non-negative integers needed by the representative test.
- Preserve all task-1 Fibonacci function and CLI behavior.

Extend repository-root `math-tool.Tests.ps1` with objective, compact Pester coverage that:

- Tests `Get-Factorial` as a pure function for `N=0`, `N=1`, and at least one small representative value greater than 1.
- Tests factorial direct CLI behavior in a separate `pwsh` child process.
- Verifies exact factorial output, including spelling, capitalization, parentheses, spaces, and numeric value.
- Retains and passes the Fibonacci unit and isolated CLI tests from task 1.
- Exercises dispatch for both supported operation values so a hard-coded or ignored operation cannot pass.
- Verifies each child process exits successfully.

Use the interface established by the merged task-1 implementation as the compatibility baseline; make the smallest extension needed for operation selection and factorial support.

## Completion gates

- Run `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`; the combined regression suite must exit zero.
- The pinned pull-request CI must pass using Pester 5.7.1.
- Unit assertions must prove `Get-Factorial` returns numeric `1` for both `N=0` and `N=1`, with no incidental output.
- Include a discriminating representative case, such as `N=5` producing numeric `120` and exact CLI output `Factorial(5) = 120`, so base-case-only or additive implementations cannot pass.
- Isolated CLI assertions must prove factorial execution emits one and only one stdout line and that Fibonacci still emits its exact task-1 line.
- Dispatch tests must invoke both `fibonacci` and `factorial` through the public script parameters and demonstrate that the selected operation controls both calculation and label.
- Confirm all task-1 Fibonacci tests remain present and passing.
- Confirm the PR changes are limited to the math tool and its tests unless a strictly necessary integration adjustment is demanded by the existing runner.

## Out of scope

- Do not change the pinned Pester version, replace the repository-owned runner, or weaken the workflow.
- Do not redesign or rename the merged Fibonacci behavior except where the new `Operation` parameter strictly requires dispatch integration.
- Do not add operations beyond Fibonacci and factorial, interactive prompts, formatting options, modules, packages, or unrelated cleanup.
- Do not broaden input behavior beyond the plan's non-negative integer contract.
