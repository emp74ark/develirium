---
name: install
description: 'Set up the deliver extension in the current project: copy the profile and config templates into .agents/ and update .gitignore. Existing files are never overwritten.'
disable-model-invocation: true
effort: low
---

# Deliver: install

Run the setup script from the project root and show its output unchanged:

```bash
bash "$(dirname "$SKILL_FILE")/../scripts/install.sh"
```

It creates `.agents/deliver.profile.md` and `.agents/config.yml` from the extension's templates when they are missing, and adds `/.worktrees/` and `/.agents/config.local.yml` to `.gitignore`. It never overwrites a file.

Then fill in the profile. If `.agents/deliver.profile.md` was just created:

1. Look at the project: `package.json` scripts, `nx.json`, `Makefile`, CI workflows, the base branch (`git symbolic-ref refs/remotes/origin/HEAD`), and the rules files (`AGENTS.md`, `CLAUDE.md`).
2. Propose values for the profile's commands, base branch, branch prefix, and required checks. Ask the user to confirm before editing the file. See `references/profile.example.md` in the deliver skill's folder for a filled-in profile example.
3. Tell the user that `/deliver <issue number | issue URL | task>` is ready to use.

If the profile already existed, only report what was kept.
