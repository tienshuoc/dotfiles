---
name: landing-reviewed-changes
description: Take uncommitted, agent-written changes through an independent review loop until findings converge, then land them as small commits the user approves one at a time. Use when the user asks to review changes until convergence, or to stage changes into logical commits for explicit approval.
{{- if .claude }}
disable-model-invocation: true
{{- end }}
---

# Landing reviewed changes

Use this workflow after an implementation is complete and still uncommitted. It
counters automation bias: an independent reviewer finds defects, a separate
verifier tries to refute each finding, scripted checks surface risky edits, and
the user approves every commit after reading its risks.

## Rules

- Do not commit, push, open a pull request, or trigger CI without the user's
  explicit approval for that specific action. Approval to continue the work is
  not approval to commit.
- Back every claim with evidence: the command run and the relevant output. Do
  not report a build or test as passing unless it ran in this session.
- Do not stash, reset, or discard changes the user made outside this task
  without asking.
- Read build, test, format, commit-message, and pull-request conventions from
  the repository's instructions. Do not hardcode them.
- Rank findings P0-P3: P0 blocks release, P1 is an urgent defect, P2 is an
  ordinary defect, and P3 is low impact but worth fixing.
- This workflow names the `review-agent` and `code-review` skills. When either
  is unavailable, give a subagent equivalent instructions: a read-only,
  defect-first review of the diff, or a review against repository standards and
  the specification.

## 1. Establish the baseline

1. Identify the task specification: ticket, spec file, or the user's request.
   The reviewers receive it as acceptance criteria.
2. Record the change set: `git status --short` and `git diff HEAD -M --stat`.
3. Run the repository's formatter, then build and test the touched targets.
   Record the commands and results.

## 2. Run the review loop

Each round:

1. **Review.** In round 1, spawn a reviewer subagent that follows the
   `review-agent` skill on the uncommitted changes. Give it only the review
   target and the acceptance criteria, not your reasoning or summary of the
   change. In later rounds, resume the same reviewer and tell it what changed
   and which findings were refuted, with evidence.
2. **Verify each finding.** For each P0-P2 finding, spawn a verifier subagent
   that tries to refute it by tracing or reproducing the failure path. Fix only
   confirmed findings. Judge P3 findings yourself; fix them or list them for
   the user.
3. **Fix narrowly.** Change only what a confirmed finding requires. Treat test
   files as read-only unless the finding is about the test itself.
4. **Re-validate.** Run the formatter and the targeted build and tests again.

Stop the loop when a round produces no new confirmed P0-P2 finding. Stop after
5 rounds regardless, and report the open findings and disagreements to the user
instead of continuing.

Then run a final pass in parallel:

- a fresh reviewer following `review-agent`, with no history from the loop
- the `code-review` skill, for repository standards and conformance to the
  specification, including scope creep and missing requirements

A new confirmed P0-P2 finding returns the change to the loop and counts toward
the round cap. When the final pass is clean, run the full test suite that
covers the change once.

## 3. Scan for red flags

Scan the full diff and list every occurrence of:

- edited, deleted, or renamed test files
- removed or weakened assertions, test expectations, and validation checks,
  such as deleted asserts, loosened tolerances, broadened expected outputs,
  and newly expected failures
- deleted or shortened comments and docstrings
- new dependencies, imports, or includes; confirm each one exists in the
  build graph, registry, or source tree
- new `TODO`, `FIXME`, lint suppressions, skipped or disabled tests
- files or hunks that do not map to the task specification

Each flag is either justified in the commit plan or fixed before staging.

## 4. Propose a commit plan

Split the change into logical groups and present the whole plan before staging
anything. For each group, list the files or hunks, the purpose, and the
proposed commit message.

- Each commit builds and passes its tests on its own.
- Keep tests in the same commit as the code they cover.
- Keep moves, renames, and mechanical refactors separate from behavior changes.
- Warn when a commit exceeds about 400 changed lines, and propose a split.

Wait for the user to approve or reorder the plan.

## 5. Stage and approve each commit

For each group, in plan order:

1. Stage only that group's files or hunks (`git add <paths>`, or
   `git apply --cached` for partial files).
2. Check the staged tree on its own when the build is cheap enough, for example
   in a temporary `git worktree` with the staged patch applied. Otherwise state
   that only the final commit was built and tested.
3. For a commit that adds tests and changes behavior, revert the
   implementation in the temporary tree and confirm that the new tests fail.
4. Show the approval card, then `git diff --cached`:

   ```
   Commit <n>/<total>: <subject>
   Why:          <reason this change exists>
   Could break:  <behaviors and callers at risk>
   Check:        <specific hunks the user should read closely>
   Evidence:     <commands run and results; fails-on-revert result>
   Red flags:    <flags from step 3 in this commit, or "none">
   Size:         <+added/-removed lines, files>
   ```

5. Wait for the user to approve, edit the message, split the group, or reject
   it. Commit only after approval.

Apply later fixes to an approved commit with `git commit --fixup` and an
autosquash rebase, after the user approves both.

## 6. Finish

Offer each remaining step separately and wait for approval of each: push the
branch, open a draft pull request, and trigger CI or regression runs. Report
results with links and distinguish requested runs from completed ones.

End with a summary: review rounds run, confirmed and refuted findings, P3
findings left open, red flags and their resolution, commits made, and any
validation not run.
