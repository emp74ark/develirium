# Changelog

One version number for both consumers — the Claude plugin
(`plugins/deliver/.claude-plugin/plugin.json`) and the Junie extension
(`extensions/deliver/extension.json`) are bumped together on every release,
even when a change only affects one of them. Each entry below says which
consumer(s) it applies to. Versions follow [semver](https://semver.org):
patch for behavior-preserving fixes, minor for backward-compatible
additions, major for breaking changes.

## 0.4.0

- **Antigravity (new).** Added Google Antigravity support. The repo root is an
  Antigravity plugin (`.antigravity-plugin/plugin.json`) with a `deliver`
  skill in `skills/deliver/` (orchestrator, `references/`, `scripts/`) and four
  subagents in `agents/`. `scripts/install.sh antigravity` installs it with
  `agy plugin install`, or copies it to `~/.gemini/config/plugins/deliver`
  when `agy` is missing. The manifest carries the shared version number and
  passes `agy plugin validate --strict`. The Claude plugin and the Junie
  extension are unchanged.

## 0.3.1

- **Claude plugin.** The `run` skill now loads `workflow.md` into the prompt
  with a shell injection instead of asking Claude to `Read` it from the plugin
  cache. The read sat outside the project, so project-scope installs got a
  "read outside the working directories" prompt on every run. The Junie
  extension is unchanged.

## 0.3.0

- **Both.** Added `version` to `extension.json` as the Junie extension's own
  source of truth (it previously had none; only the marketplace catalog
  entry carried a version). Aligned the plugin and extension on a single
  shared version number across both manifests and both marketplace catalogs,
  to avoid tracking independent version numbers per consumer.

## 0.2.1

- **Claude plugin only.** Fixed `plugins/deliver/skills/run/SKILL.md`'s
  dynamic frontmatter, which used a shell `for` loop over `$f` to read
  `.agents/config.yml` / `.agents/config.local.yml`. Claude Code's
  skill-frontmatter shell check refuses any command containing a variable,
  so `/deliver:run` failed to load. Replaced with a variable-free
  `cat .agents/config.yml .agents/config.local.yml 2>/dev/null || true`.
  Not applicable to the Junie extension, whose skill has no dynamic shell
  frontmatter.

## 0.2.0 / 1.0.0

- Initial tracked versions, before the two consumers were aligned on one
  number: Claude plugin `0.2.0` (`/deliver:run`, `/deliver:install`,
  planner/plan-reviewer/implementer/implementation-reviewer subagents).
  Junie extension `1.0.0` (`/deliver`, `/deliver:install`, role-switching
  orchestrator self-played by Junie).
