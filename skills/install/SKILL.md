---
name: install
description: 'Set up the deliver plugin in the current project: copy the profile and config templates into .agents/ and update .gitignore. Existing files are never overwritten.'
---

# Deliver: install

Run the setup script [install.sh](../deliver/scripts/install.sh) from the project root and show its output unchanged:

```bash
bash "$(dirname "$0")/../deliver/scripts/install.sh"
```
Or execute [install.sh](../deliver/scripts/install.sh) directly with bash in the current project directory.

It creates `.agents/deliver.profile.md` and `.agents/config.yml` from the plugin templates when they are missing, and adds `/.worktrees/` and `/.agents/config.local.yml` to `.gitignore`. It never overwrites a file.

Then inspect the project and help fill in the profile. If `.agents/deliver.profile.md` was just created:

1. Look at the project: `package.json` scripts, `nx.json`, `Makefile`, CI workflows (`.github/workflows/`), the base branch (`git symbolic-ref refs/remotes/origin/HEAD` or `git remote show origin`), and the rules files (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`).
2. Propose values for the profile's commands, base branch, branch prefix, and required checks. Ask the user to confirm before editing the file. See [profile.example.md](../deliver/references/profile.example.md) and [nx-monorepo.profile.md](../deliver/references/examples/nx-monorepo.profile.md) in the deliver skill's folder for reference.
3. Tell the user that `/deliver <issue number | issue URL | task>` is ready to use.

If the profile already existed, report what was kept.
