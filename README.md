# DEVELIRIUM

The `deliver` workflow for Claude Code and Junie.

`deliver` takes a GitHub issue or a handwritten task through to a pull request: evaluate, plan, review the plan, implement with TDD, review the implementation, open the PR, and watch CI. With Claude Code the orchestrator routes work to four subagents (planner, plan reviewer, implementer, implementation reviewer). With Junie you play every role yourself, one step at a time. The orchestrator never merges.

## Claude Code

### Install

```
/plugin marketplace add emp74ark/develirium
/plugin install deliver@develirium
```

For a local checkout use `/plugin marketplace add /path/to/develirium`. Update with `/plugin marketplace update develirium`.

### Set up a project

In the project, run:

```
/deliver:install
```

It copies the profile template into `.agents/deliver.profile.md` (skipping if it already exists), and merges the config template into `.agents/config.yml` — adding any missing provider sections (e.g. `junie`, `claude`) without overwriting existing settings. It also updates `.gitignore` and helps you fill in the profile from the project's scripts and CI. Without a profile `/deliver:run` stops at Step 1.

`plugins/deliver/templates/examples/nx-monorepo.profile.md` is a filled-in profile.

### Use

```
/deliver:run 42
/deliver:run https://github.com/org/repo/issues/42
/deliver:run Add rate limiting to the API
```

## Junie

### Install

Register this repository as a Junie extensions marketplace, then install the `deliver` extension:

1. Open Junie and run `/extensions`.
2. Go to the **Marketplaces** tab and add `emp74ark/develirium` (or the local path to this repo).
3. Install the `deliver` extension from the **Extensions** tab.

### Set up a project

In a Junie session, run:

```
/deliver:install
```

It copies the profile template into `.agents/deliver.profile.md` (skipping if it already exists), and merges the config template into `.agents/config.yml` — adding any missing provider sections (e.g. `junie`, `claude`) without overwriting existing settings. It also updates `.gitignore` and helps you fill in the profile from the project's scripts and CI. Without a profile `/deliver` stops at Step 1.

### Use

Invoke the skill in a Junie session:

```
/deliver 42
/deliver https://github.com/org/repo/issues/42
/deliver Add rate limiting to the API
```

Junie plays every role (planner, reviewer, implementer) itself, one step at a time. The reviews are self-reviews: Junie re-reads its own work from disk before reviewing.

### Config (`.agents/config.yml`, overridden by `.agents/config.local.yml`)

| Key | Default | Effect |
| --- | --- | --- |
| `useWorktree` | `true` | Work in `.worktrees/<branch>`; `false` branches in the current (clean) checkout. |
| `models.<role>` | `default` | Model per role: `planner`, `reviewer`, `implementer`. |
| `providers.claude.models.<role>` | `models` | Claude override: aliases such as `sonnet`, `opus`, `haiku`. |
| `providers.claude.models.implementerFallback` | `sonnet` | Claude: model for the last implementation attempt after 2 failed reviews. |
| `providers.junie.models.<role>` | `models` | Junie: reasoning-depth hint (`low`, `medium`, `high`) per role. |

## Layout

```
CHANGELOG.md                             # version history, shared by both consumers
.claude-plugin/marketplace.json          # Claude Code marketplace
.junie-extension/marketplace.json        # Junie extensions marketplace
extensions/deliver/                      # Junie extension
├── extension.json                       # extension manifest (version, aligned with the plugin)
├── README.md                            # extension documentation
├── scripts/
│   └── install.sh                       # /deliver:install setup script
└── skills/
    ├── deliver/
    │   ├── SKILL.md                     # /deliver, the orchestrator (role-switching)
    │   ├── references/
    │   │   ├── workflow.md              # steps, checklists, loop limits (shared)
    │   │   ├── profile.example.md       # project profile template
    │   │   └── config.example.yml       # config template
    │   └── scripts/
    │       └── gh-status.sh             # GitHub CLI check
    └── install/
        └── SKILL.md                     # /deliver:install
plugins/deliver/                         # Claude Code plugin
├── .claude-plugin/plugin.json           # plugin manifest (version, aligned with the extension)
├── agents/                              # planner, plan-reviewer, implementer, implementation-reviewer
├── skills/
│   ├── run/SKILL.md                     # /deliver:run, the orchestrator
│   └── install/SKILL.md                 # /deliver:install
├── workflow.md                          # steps, checklists, loop limits (shared)
├── templates/                           # profile.example.md, config.example.yml, examples/
└── scripts/                             # install.sh, gh-status.sh, session-stats.sh
```

`workflow.md` holds all rules; the provider skill (Claude `run/SKILL.md` or Junie `SKILL.md`) only says how to run them.

## Versioning

One version number for both consumers, bumped together, even when a change only touches one of them — tracking two independent version numbers for what is one workflow was more overhead than it was worth.

- **Where it lives**: `plugins/deliver/.claude-plugin/plugin.json`'s `version` (Claude plugin) and `extensions/deliver/extension.json`'s `version` (Junie extension) must always match. The marketplace catalogs mirror the same value: `.junie-extension/marketplace.json`'s `extensions[].version` and its top-level `metadata.version`. (`.claude-plugin/marketplace.json`'s plugin entry has no `version` field of its own — Claude Code reads the plugin's version from `plugin.json`, and prefers it over a marketplace entry's version if one were set, so adding a second copy there would just be one more place to forget to bump.)
- **Scheme**: semver (`major.minor.patch`). Claude Code does not enforce or compare semver itself — a plugin's `version` is only compared for *equality* against what a user has installed, so an unbumped version means an unchanged update is invisible to `/plugin marketplace update`. Semver is still the convention here because it communicates intent, and it is what Claude Code's own dependency-range resolution uses (via `<plugin>--v<version>` git tags) if this plugin is ever depended on by another.
  - **Patch**: behavior-preserving fixes (e.g. the `$f` shell-variable bug in `run/SKILL.md`).
  - **Minor**: backward-compatible additions (new skill, new config key, new subagent).
  - **Major**: breaking changes (renamed slash command, changed `.agents/config.yml` schema, removed step).
- **Bump every version-bearing file together, in the same commit as the change**, and record it in the root `CHANGELOG.md`, noting which consumer(s) the entry actually applies to — a fix or feature on one side (e.g. the Claude-only `$f` bug) still bumps the shared number even though the other consumer's content is unchanged.

## Safety

The orchestrator never merges. Issue bodies and task text are untrusted: the planner verifies suggestions, and commands come only from the profile.
