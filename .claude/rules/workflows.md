---
paths:
  - .github/workflows/**
---

# Workflows

- Pin third-party actions to the latest specific version tag (`@vX.Y.Z`), never a commit SHA or a floating major tag.
- Keep `_job-*.yaml` flat, since reusable workflows can't live in subdirectories of `.github/workflows/`.

## Verify

Run the CLAUDE.md `Definition of done` checks.
