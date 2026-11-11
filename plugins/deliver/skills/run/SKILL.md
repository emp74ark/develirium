---
name: run
description: "Deliver a GitHub issue or a handwritten task end to end: evaluate it, write the plan, review the plan, implement, review the implementation, open a pull request and watch CI. Claude Code plugin: runs planner, reviewer and implementer subagents."
argument-hint: "<issue number | issue URL | task description>"
disable-model-invocation: true
effort: medium
---

# Deliver

Read the shared workflow first: `${CLAUDE_PLUGIN_ROOT}/workflow.md`. It holds the steps, checklists, loop limits, and verification rules. The project profile, `.agents/deliver.profile.md`, holds the project's commands, plan location, and required checks. This skill only says how to run the workflow in Claude Code.

You are the orchestrator. You do not plan, write code, or review code yourself. You route work to subagents, pass their results between them, talk to the user, and run git and `gh`. Keep your own context small: pass file paths to subagents, not file contents.

Input: `$ARGUMENTS`

Workflow file: `${CLAUDE_PLUGIN_ROOT}/workflow.md`. Profile: `.agents/deliver.profile.md` (if it is missing, stop and tell the user to copy `${CLAUDE_PLUGIN_ROOT}/templates/profile.example.md` there and edit it, or run `/deliver:install`).

Agent settings (`.agents/config.yml`, then `.agents/config.local.yml`; a later key wins):

```yaml
!`cat .agents/config.yml .agents/config.local.yml 2>/dev/null || true`
```

GitHub CLI status: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/gh-status.sh`

This status is Step 1's check; do not run it again.

### Subagents

The subagents come with this plugin. Spawn them by their namespaced type (`subagent_type`), as in the table.

| Step                         | Subagent                          | Model key     |
| ---------------------------- | --------------------------------- | ------------- |
| 4: Plan                      | `deliver:planner`                 | `planner`     |
| 5: Review the plan           | `deliver:plan-reviewer`           | `reviewer`    |
| 7: Implement                 | `deliver:implementer`             | `implementer` |
| 8: Review the implementation | `deliver:implementation-reviewer` | `reviewer`    |

Model for each spawn: `providers.claude.models.<key>` from the settings above, else `models.<key>`. Pass it as the Agent tool's `model`. When the value is `default`, omit `model`; the subagent then runs on this session's model. The subagent files say `model: inherit`, so they take the model you pass.

Run every subagent in the foreground: each step depends on the previous one. Every prompt contains the absolute working directory, tells the subagent to work only inside it, and names the inputs below plus the absolute paths of the workflow file and the profile. Pass paths, not contents.

### Steps

1. **Prerequisites.** Use the settings and `gh` status above.
2. **Read the task.** Ask about opening an issue with AskUserQuestion.
3. **Create the branch.** As in the shared workflow.
4. **Plan.** Spawn `deliver:planner` with the task text or issue number, the working directory, and the branch name. On `NEEDS_CLARIFICATION`, put the questions to the user with AskUserQuestion, then spawn the planner again with the answers. If it says the task should not be done, tell the user and stop.
5. **Review the plan.** Spawn `deliver:plan-reviewer` with the working directory, the plan path, and the task text. On `REVISE`, spawn `deliver:planner` with the findings, then review again.
6. **Approve.** Ask the user with AskUserQuestion, then commit the plan as the shared workflow says.
7. **Implement.** Spawn `deliver:implementer` once per delivery stage, in order, with the working directory, the plan path, and the stage. On `BLOCKED`, resolve it from the plan if you can; otherwise ask the user.
8. **Review the implementation.** Spawn `deliver:implementation-reviewer` with the working directory, the plan path, and the task text. On `CHANGES_REQUESTED`, spawn `deliver:implementer` with the findings, then review again. After 2 failed rounds, spawn `deliver:implementer` once more with `model` set to `providers.claude.models.implementerFallback`. If the review still fails, show the findings to the user and stop.
9. **Open the pull request.** As in the shared workflow.
10. **Watch CI.** Run `gh pr checks <pr> --watch --fail-fast` with the Bash tool in the foreground, with `timeout: 600000`. If it times out while checks are still pending, run it again. Never run it in the background: the continuation would run on the session model, outside this skill. Fix rounds spawn `deliver:implementer` as in the shared workflow.
11. **Report.** As in the shared workflow, then run:

    ```bash
    bash ${CLAUDE_PLUGIN_ROOT}/scripts/session-stats.sh ${CLAUDE_SESSION_ID}
    ```

    Add a `Session stats` section with the output unchanged. The script no longer checks the model of `inherit` subagents, so its `Match` column shows `yes` for them without a check and their `Expected model` cell is blank. The model check is therefore yours: compare each subagent row's `Used model` with the model you passed for it in the table above. When you passed no model (`default`), compare with this session's model, the orchestrator row. Name each step whose model differs, and why if you know (for example the Sonnet retry in Step 8).
