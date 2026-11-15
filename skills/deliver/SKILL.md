---
name: deliver
description: 'Deliver a GitHub issue or a handwritten task end to end: evaluate it, write the plan, review the plan, implement, review the implementation, open a pull request and watch CI. Antigravity plugin skill: runs the planner, reviewer and implementer roles, as subagents when available, otherwise yourself.'
---

# Deliver

Read the shared workflow first: [workflow.md](./references/workflow.md) in this skill's folder. It holds the steps, checklists, loop limits, and verification rules. The project profile, `.agents/deliver.profile.md`, holds the project's commands, plan location, and required checks. This skill describes how to run the workflow in Antigravity.

Read `AGENTS.md` (or `GEMINI.md`) if it exists, then the profile, then the shared workflow.

Input: a task description, an issue number, or an issue URL.

## Roles

The plugin ships four subagents in `agents/` at the plugin root (`../../agents/` from this skill's folder):

| Step                         | Subagent / Role           | TypeName                   | Model Key     |
| ---------------------------- | ------------------------- | -------------------------- | ------------- |
| 4: Plan                      | Planner                   | `planner`                  | `planner`     |
| 5: Review the plan           | Plan Reviewer             | `plan-reviewer`            | `reviewer`    |
| 7: Implement                 | Implementer               | `implementer`              | `implementer` |
| 8: Review the implementation | Implementation Reviewer   | `implementation-reviewer`  | `reviewer`    |

You are the orchestrator (Steps 1–3, 6, and 9–11): manage git and `gh`, coordinate roles, and interact with the user.

### Execution Mode

1. **Subagents mode (preferred):** When your environment supports spawning subagents (`invoke_subagent`), spawn the subagent named in the table. Pass `Model` from `providers.antigravity.models.<key>` in `.agents/config.yml` (e.g. `inherit`, `pro`, `flash`; omit or use `inherit` when set to `default`). Pass paths, not contents: the absolute path of the working directory, the workflow file [workflow.md](./references/workflow.md), the profile, and the step's specific inputs.
2. **Single-agent mode (fallback):** If subagents cannot be spawned, play each role yourself: read its agent definition in `../../agents/<name>.md` first, and work strictly as that role until the step is complete. When self-reviewing (Steps 5 and 8), always re-read files from disk rather than relying on memory.

`providers.antigravity.models` in `.agents/config.yml` specifies the subagent model tier (`inherit`, `pro`, `flash`) or reasoning-depth hint: reason more thoroughly as planner and reviewer, and focus on fast execution as implementer.

## Steps

1. **Prerequisites.** Read the settings (`.agents/config.yml`, then `.agents/config.local.yml`) and the profile (`.agents/deliver.profile.md`). If the profile is missing, run the install skill (`/deliver:install`), or run [install.sh](./scripts/install.sh) from this skill's folder in the project root. Then stop and ask the user to fill in `.agents/deliver.profile.md`. Run [gh-status.sh](./scripts/gh-status.sh) from this skill's folder. Unless the status is `gh: ready`, stop and tell the user how to fix it.

2. **Read the task.** Follow Step 2 of the shared workflow. Ask the user in chat whether to open a GitHub issue for a handwritten task, and wait for the answer before proceeding.

3. **Create the branch.** Follow Step 3 of the shared workflow.

4. **Plan.**
   - *Subagent:* Spawn `planner` with the task description or issue number, the working directory, and the branch name.
   - *Fallback:* Work as the **planner** and follow Step 4 of the shared workflow.
   - On `NEEDS_CLARIFICATION`, present the questions to the user in chat and wait for answers, then continue planning. If the task should not be done, explain why to the user and stop.

5. **Review the plan.**
   - *Subagent:* Spawn `plan-reviewer` with the working directory, the plan path, and the task text. On `REVISE`, spawn `planner` with the findings, then review again. At most 2 revision rounds.
   - *Fallback:* Work as the **plan reviewer** and follow Step 5 of the shared workflow. Re-read the plan from disk, evaluate against the checklist, and if `REVISE`, switch to **planner** to fix findings and re-review.

6. **Approve.** Show the user the plan path, a 5-line summary of its stages, and any rejected suggestions with reasons. Ask whether to proceed to implementation and wait for confirmation. Upon approval, commit the plan as specified in the shared workflow.

7. **Implement.**
   - *Subagent:* Spawn `implementer` for one delivery stage at a time, in order, passing the working directory, the plan path, and the stage details.
   - *Fallback:* Work as the **implementer** and follow Step 7 of the shared workflow for one stage at a time.
   - On `BLOCKED`, resolve from the plan if possible, otherwise ask the user.

8. **Review the implementation.**
   - *Subagent:* Spawn `implementation-reviewer` with the working directory, the plan path, and the task text. On `CHANGES_REQUESTED`, spawn `implementer` with the findings, then review again. At most 2 fix rounds.
   - *Fallback:* Work as the **implementation reviewer** and follow Step 8 of the shared workflow. Freshly inspect `git diff origin/<base>...HEAD` and run verification commands. If changes are requested, switch to **implementer** to fix and re-review.

9. **Open the pull request.** Follow Step 9 of the shared workflow.

10. **Watch CI.** Follow Step 10 of the shared workflow. Run `gh pr checks <pr> --watch --fail-fast` in the foreground. If it times out while checks are still pending, run it again. On a required check failure, fix it with the **implementer** (spawn subagent or play role), push, and watch again. At most 3 fix rounds.

11. **Report.** Follow Step 11 of the shared workflow. If you played the reviewer roles yourself, state in the report that the reviews were self-reviews. List the review rounds and pull request URL.
