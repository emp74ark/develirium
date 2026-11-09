---
name: deliver
description: 'Deliver a GitHub issue or a handwritten task end to end: evaluate it, write the plan, review the plan, implement, review the implementation, open a pull request and watch CI. Junie skill: you play every role (planner, reviewer, implementer) yourself.'
argument-hint: '<issue number | issue URL | task description>'
disable-model-invocation: true
effort: medium
---

# Deliver

Read the shared workflow first: `references/workflow.md` in this skill's folder. It holds the steps, checklists, loop limits, and verification rules. The project profile, `.agents/deliver.profile.md`, holds the project's commands, plan location, and required checks. This skill only says how to run the workflow in Junie.

Read `AGENTS.md` if it exists, then the profile (`.agents/deliver.profile.md`), then the shared workflow. The workflow holds the steps, checklists, loop limits, and verification rules.

Input: a task description, an issue number, or an issue URL.

## Roles

You play every role yourself, one step at a time, in the order of the shared workflow. When a step names a role, work only as that role:

- **Orchestrator**: Steps 1-3, 6, 9-11. Run git, `gh`, talk to the user.
- **Planner**: Step 4. Write the plan and specs, no application code.
- **Plan reviewer**: Step 5. Read-only. Do not edit files while reviewing.
- **Implementer**: Step 7. One delivery stage at a time.
- **Implementation reviewer**: Step 8. Read-only. Do not edit files while reviewing.

`providers.junie.models` in `.agents/config.yml` is a hint for reasoning depth: reason more thoroughly as planner and reviewer, and focus on execution as implementer.

## Steps

1. **Prerequisites.** Read the settings (`.agents/config.yml`, then `.agents/config.local.yml`) and the profile. If the profile is missing, stop and tell the user to run the `install` skill first (`/deliver:install`), then edit `.agents/deliver.profile.md`. Run `bash scripts/gh-status.sh` from this skill's folder. Unless the status is `gh: ready`, stop and tell the user the fix.

2. **Read the task.** Follow Step 2 of the shared workflow. Ask the user in chat whether to open a GitHub issue for a handwritten task, and wait for the answer before going on.

3. **Create the branch.** Follow Step 3 of the shared workflow.

4. **Plan.** Work as the **planner** and follow Step 4 of the shared workflow. If the intention is unclear, ask the user in chat and wait for the answer. If the task should not be done, tell the user and stop.

5. **Review the plan.** Work as the **plan reviewer** and follow Step 5 of the shared workflow. You are reviewing your own plan, so start fresh:
   1. Re-read the plan file from disk. Do not rely on what you remember writing.
   2. Go through the checklist item by item and write down a verdict and findings for each before fixing anything.
   3. On `REVISE`, switch back to the **planner** role, fix the findings, then review again. At most 2 revision rounds.

6. **Approve.** Show the user the plan path, a five-line summary of its stages, and the suggestions the planner rejected with the reason for each. Ask whether to start implementing, and wait for the answer. When the user approves, commit the plan as the shared workflow says.

7. **Implement.** Work as the **implementer** and follow Step 7 of the shared workflow for one delivery stage at a time, in order. On `BLOCKED`, resolve it from the plan if you can; otherwise ask the user.

8. **Review the implementation.** Work as the **implementation reviewer** and follow Step 8 of the shared workflow. You are reviewing your own implementation, so start fresh:
   1. Re-read the plan and run `git diff origin/<base>...HEAD` and `git log origin/<base>..HEAD --oneline`. Do not rely on what you remember writing.
   2. Go through the checklist item by item and write down a verdict and findings for each before fixing anything.
   3. On `CHANGES_REQUESTED`, switch back to the **implementer** role, fix the findings, then review again. At most 2 fix rounds.

9. **Open the pull request.** Follow Step 9 of the shared workflow.

10. **Watch CI.** Follow Step 10 of the shared workflow. Run `gh pr checks <pr> --watch --fail-fast` in the foreground. If it times out while checks are still pending, run it again. On a required check failure, fix it as the **implementer**, then watch again. At most 3 fix rounds.

11. **Report.** Follow Step 11 of the shared workflow. Say in the report that the reviews were self-reviews, and list the review rounds. Session stats do not apply: they read Claude transcripts only.
