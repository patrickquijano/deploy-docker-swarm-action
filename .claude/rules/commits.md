---
description: Conventional Commits and Conventional Branch rules for commit messages and branch names.
---

# Commits and branches

## Commits

The `commit-msg` hook rejects messages that break `.commitlintrc.json` or these rules.

- Subject only: no body, no footer.
- No attribution (no `Co-Authored-By`, no "Generated with").
- Signed and verified; check with `git log --show-signature -1`.
- Atomic: one logical change per commit, related files grouped.
- Never commit secrets or credentials; read them from environment variables.

## Branches

- Conventional Branch: `<type>/<short-description>` (e.g. `feat/add-login`).
- Max 72 characters.
- Imperative, lowercase, hyphen-separated.

## Git hooks

- Never bypass hooks with `--no-verify` or by disabling Husky locally.
