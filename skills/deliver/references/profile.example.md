# Deliver profile

Copy this file to `.agents/deliver.profile.md` and edit it. The deliver workflow reads it in Step 1 and takes every project-specific value from it. Delete a line to use the default shown in brackets.

## Project

- Base branch: `main`
- Branch prefix: `<repo-name>`
- Rules files: `AGENTS.md`, `CLAUDE.md` (every role reads those that exist; also follow the subsystem rules files they point to)
- Commit rules: Conventional Commits (`<type>(<scope>): <summary>`, imperative, at most 72 characters)
- Attribution: follow the rules files; add none when they say nothing

## Commands

| Name    | Command                     | Notes                            |
| ------- | --------------------------- | -------------------------------- |
| install | `npm ci`                    | Run once in a new branch.        |
| lint    | `npm run lint`              | Per-project form, if any: `...`  |
| test    | `npm test`                  | Per-project form, if any: `...`  |
| build   | `npm run build`             |                                  |
| all     | `npm run lint && npm test`  | Run by the reviewer on the diff. |
| extra   |                             | Optional: spec linter, integration tests, and so on, with when each applies. |

## Plans

- Plan directory: `docs/plan/active/` [`docs/plan/`]
- Plan template: none [built in: see Step 4 of the workflow]
- Other spec templates: none (ADR, CUJ, schema notes, and so on, with their directories)
- Plan frontmatter: none

## Pull requests

- Required checks: all [list the check names]
- Informational checks: none
- Plan link in the PR body: yes

## Review checklist additions

Extra items for the plan reviewer and implementation reviewer, for example security rules, coverage thresholds, compatibility rules for shared libraries, or documentation that must be updated.
