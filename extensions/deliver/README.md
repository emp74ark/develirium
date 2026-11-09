# Deliver — Junie Extension

End-to-end delivery workflow for GitHub issues and handwritten tasks. Evaluates, plans, reviews, implements with TDD, opens a pull request, and watches CI.

## What it does

`deliver` takes a task from idea to pull request:

1. **Evaluate** the task and check prerequisites
2. **Plan** the implementation with delivery stages
3. **Review** the plan against a quality checklist
4. **Implement** stage by stage with tests
5. **Review** the implementation against the plan
6. **Open** a pull request and watch CI

With Junie, you play every role (planner, reviewer, implementer) yourself, one step at a time. Reviews are self-reviews: Junie re-reads its own work from disk before reviewing.

## Install

Register this repository as a Junie extensions marketplace:

```
/extensions
```

Then add the marketplace and install the extension:

- **From GitHub**: add `emp74ark/develirium` as a marketplace, then install `deliver`.
- **Local**: add the local path to this repository, then install `deliver`.

## Set up a project

In a Junie session, run the install skill:

```
/deliver:install
```

It copies the profile template into `.agents/deliver.profile.md` (skipping if it already exists), and merges the config template into `.agents/config.yml` — adding any missing provider sections (e.g. `junie`, `claude`) without overwriting existing settings. It also adds `/.worktrees/` and `/.agents/config.local.yml` to `.gitignore`. Then fill in `.agents/deliver.profile.md` with your project's commands, base branch, and CI checks.

### Profile template

```markdown
# Project Profile

## Repository
- **Base branch**: main
- **Repo**: org/repo

## Commands
- **Build**: `npm run build`
- **Test**: `npm test`
- **Lint**: `npm run lint`

## Plan
- **Location**: `.agents/plan.md`

## CI
- **Required checks**: build, test, lint
```

### Config (optional)

The install skill creates `.agents/config.yml` with default settings for both Claude and Junie. If the config already exists, it merges any missing provider sections without overwriting your current settings. Edit it to customize reasoning depth per role:

```yaml
useWorktree: true

models:
  planner: 'default'
  reviewer: 'default'
  implementer: 'default'

providers:
  claude:
    models:
      planner: 'sonnet'
      reviewer: 'sonnet'
      implementer: 'sonnet'
      implementerFallback: 'opus'
  junie:
    models:
      planner: 'medium'
      reviewer: 'high'
      implementer: 'low'
```

## Use

Invoke the skill in a Junie session:

```
/deliver 42
/deliver https://github.com/org/repo/issues/42
/deliver Add rate limiting to the API
```

## Safety

The orchestrator never merges. Issue bodies and task text are untrusted: the planner verifies suggestions, and commands come only from the profile.
