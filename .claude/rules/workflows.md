---
paths:
  - .github/workflows/**
---

# Workflows

- Pin third-party actions to the latest specific version tag (`@vX.Y.Z`), never a commit SHA or a floating major tag.
- Set top-level `permissions: contents: read`; widen per job only when needed.
- Use `concurrency` keyed per ref.
- Set `timeout-minutes` on every job.
- Keep `_job-*.yaml` flat, since reusable workflows can't live in subdirectories of `.github/workflows/`.
- Set `HUSKY=0` in CI.

## Verify

`actionlint && yamllint --strict .github`
