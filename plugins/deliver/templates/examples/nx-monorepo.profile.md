# Deliver profile (example: Nx monorepo)

## Project

- Base branch: `main`
- Branch prefix: `acme`
- Rules files: `AGENTS.md`, plus the `AGENTS.md` inside each app or library the task touches
- Commit rules: Conventional Commits, `<type>(<scope>): <summary>`; the scope is an Nx project name; imperative, at most 72 characters
- Attribution: none

## Commands

| Name    | Command                                                 | Notes                                           |
| ------- | ------------------------------------------------------- | ----------------------------------------------- |
| install | `npm ci`                                                |                                                 |
| lint    | `npx nx lint <project>`                                 |                                                 |
| test    | `npx nx test <project>`                                 | `-- <file>` runs one file.                      |
| build   | `npx nx build <project>`                                |                                                 |
| all     | `npx nx affected -t lint test build --base=origin/main` | Run by the reviewer.                            |
| extra   | `npx nx e2e <app>-e2e`                                  | When the change touches a user-facing app.      |

Use `npx nx` for every target and npm for packages.

## Plans

- Plan directory: `docs/plans/`
- Plan template: none (built-in format)
- Other spec templates: ADRs in `docs/adr/` for architecture decisions
- Plan frontmatter: none

## Pull requests

- Required checks: `ci`
- Informational checks: none
- Plan link in the PR body: yes

## Review checklist additions

- Changes to a shared library (`libs/*`) keep every dependent project building: `nx affected` covers it.
- Module boundaries hold (`@nx/enforce-module-boundaries` lint rule); no deep imports between projects.
- No implicit `any`.
