---
paths:
  - action.yaml
---

# Action

## Steps

- Pass inputs through `env:`; never inline `${{ inputs.* }}` inside `run:` (script injection).

## Verify

Run the CLAUDE.md `Definition of done` checks; behavior is proven by `_job-self-test.yaml` in CI.
