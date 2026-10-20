---
paths:
  - tests/**
  - .github/workflows/**
---

# Testing

## Unit tests (bats)

- Use bats only for inline workflow and action steps, such as `tests/check-release.bats` and `tests/setup.bats` (the step script is extracted with `yq`).
- Put negative cases in bats, not the self-test: a failing `uses:` step leaves error annotations on a green run, even with `continue-on-error`.

## Verify

Run the CLAUDE.md `Definition of done` checks; the self-test (`_job-self-test.yaml`) runs only in CI.
