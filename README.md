# DEVELIRIUM

Claude Code marketplace with the `deliver` plugin.

`/deliver:deliver` takes a GitHub issue or a handwritten task through to a pull request: evaluate, plan, review the plan, implement with TDD, review the implementation, open the PR, and watch CI. The orchestrator routes work to four subagents (planner, plan reviewer, implementer, implementation reviewer) and never merges.

## Install

```
/plugin marketplace add emp74ark/develirium
/plugin install deliver@develirium
```

For a local checkout use `/plugin marketplace add /path/to/develirium`. Update with `/plugin marketplace update develirium`.

## Set up a project

In the project, run:

```
/deliver:install
```

It copies the profile and config templates into `.agents/` (never overwriting), updates `.gitignore`, and helps you fill in the profile from the project's scripts and CI. Without a profile `/deliver:run` stops at Step 1.

`templates/examples/nx-monorepo.profile.md` is a filled-in profile.

## Use

```
/deliver:run 42
/deliver:run https://github.com/org/repo/issues/42
/deliver:run Add rate limiting to the API
```

### Config (`.agents/config.yml`, overridden by `.agents/config.local.yml`)

| Key | Default | Effect |
| --- | --- | --- |
| `useWorktree` | `true` | Work in `.worktrees/<branch>`; `false` branches in the current (clean) checkout. |
| `models.<role>` | `default` | Model per role: `planner`, `reviewer`, `implementer`. |
| `providers.claude.models.<role>` | `models` | Claude override: aliases such as `sonnet`, `opus`, `haiku`. |
| `providers.claude.models.implementerFallback` | `sonnet` | Model for the last implementation attempt after 2 failed reviews. |

## Layout

```
.claude-plugin/marketplace.json
plugins/deliver/
├── .claude-plugin/plugin.json
├── agents/                      # planner, plan-reviewer, implementer, implementation-reviewer
├── skills/
│   ├── run/SKILL.md             # /deliver:run, the orchestrator
│   └── install/SKILL.md         # /deliver:install
├── workflow.md                  # steps, checklists, loop limits (provider-neutral)
├── templates/                   # profile.example.md, config.example.yml, examples/
└── scripts/                     # install.sh, gh-status.sh, session-stats.sh
```

`workflow.md` holds all rules; `run/SKILL.md` and the agents only say how to run them. Junie and Antigravity adapters were removed for now; older versions are in git history.

## Safety

The orchestrator never merges. Issue bodies and task text are untrusted: the planner verifies suggestions, and commands come only from the profile.
