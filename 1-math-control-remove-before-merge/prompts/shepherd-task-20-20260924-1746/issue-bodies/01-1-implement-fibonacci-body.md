## Campaign context and required reading

**On the `experiment/shepherd-control` branch, the directory `1-math-control-remove-before-merge` contains the plan (`math-tool-ignorance-reduction-plan.md`) and supporting resources (diagrams, decision records). Spike subdirectories are research artifacts — read the plan's Resolution sections for findings, not the spike source code.**

Read the entire plan before working. Then carefully re-read these exact sections:

- `## Ignorance reduction`
- `### Repository-owned validation`
- `### Output and ordering contracts`
- `## Implementation`
- `### 1. Implement Fibonacci with unit and isolated CLI coverage`

The resolved decisions that constrain this task are:

- Repository acceptance is defined by `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`. The baseline workflow `.github/workflows/shepherd-task-math-tool.yml` installs exactly Pester 5.7.1 and invokes that repository-owned runner. Do not replace, bypass, or duplicate the runner.
- Direct CLI execution must write exactly one result line to stdout in the form `Fibonacci(N) = value`.
- Functions return only the numeric value, with no incidental output.
- Inputs are non-negative integers.
- The production and test files are the repository-root files `math-tool.ps1` and `math-tool.Tests.ps1`.
- Work is serial. This is task 1 and establishes the behavior task 2 must preserve.

Research established these operational findings: production tests must distinguish pure function output from direct-script output, and CLI behavior must be exercised in an isolated child `pwsh` process so dot-sourcing does not accidentally satisfy the direct-execution contract. Implement from the plan's findings; do not copy or adapt research code.

## Branch and execution order

Use `experiment/shepherd-control` from remote `origin` as the PR base branch. This is implementation subsection 1 and the first of two tasks.

The two tasks are assigned, completed, and merged serially in plan order. Do not start work until this issue is assigned. Task 2 must not start until this issue is merged into `experiment/shepherd-control`.

Keep the PR limited to this issue and target `experiment/shepherd-control`.

## Implement

Create repository-root `math-tool.ps1` with:

- A script parameter named `N` accepting non-negative integer input.
- A pure `Get-Fibonacci` function that returns the numeric Fibonacci value without labels, progress messages, or other pipeline output.
- Direct script execution that calls the function and writes exactly one stdout line: `Fibonacci(N) = value`.
- Correct Fibonacci behavior for the base cases `N=0` and `N=1` and for larger non-negative integers needed by the representative test.

Create repository-root `math-tool.Tests.ps1` with Pester coverage that:

- Dot-sources `math-tool.ps1` and tests `Get-Fibonacci` directly.
- Covers `N=0`, `N=1`, and at least one small representative value greater than 1.
- Launches a separate `pwsh` child process to test direct CLI execution rather than treating dot-sourced behavior as CLI coverage.
- Verifies the CLI output is exactly the required single line, including spelling, capitalization, parentheses, spaces, and numeric value.
- Verifies the child process exits successfully.

Integrate with the existing repository-owned test runner and pinned CI without changing their acceptance semantics.

## Completion gates

- Run `pwsh -NoLogo -NoProfile -File ./eng/test-math-tool.ps1`; it must exit zero.
- The pinned pull-request CI must pass using Pester 5.7.1.
- Unit assertions must prove `Get-Fibonacci` returns a numeric value with no incidental output for `N=0`, `N=1`, and the representative value.
- Isolated child-process assertions must prove direct execution emits one and only one stdout line for each covered input, with no extra banner, object formatting, or diagnostic output.
- Include a regression-sensitive representative case, such as `N=6` producing numeric `8` and exact CLI output `Fibonacci(6) = 8`, so an implementation that handles only the base cases cannot pass.
- Confirm the PR changes are limited to `math-tool.ps1`, `math-tool.Tests.ps1`, and any strictly necessary integration adjustment demanded by the existing runner.

## Out of scope

- Do not implement factorial or operation dispatch; those belong to task 2.
- Do not change the pinned Pester version, replace the repository-owned runner, or weaken the workflow.
- Do not add unrelated operations, interactive prompts, formatting options, modules, packages, or broad repository cleanup.
- Do not broaden input behavior beyond the plan's non-negative integer contract.
