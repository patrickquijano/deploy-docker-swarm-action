---
paths:
  - action.yaml
---

# Action

## Steps

- Pass inputs through `env:`; never inline `${{ inputs.* }}` inside `run:` (script injection).
- Keep the SSH key in the isolated work dir under `$RUNNER_TEMP` with mode 0600, and remove it in the final `teardown` step, which runs with `if: always()`.
- Deploy with `docker stack deploy --with-registry-auth` so workers can pull private images.

## Releases

- SemVer tags `vX.Y.Z` plus a moving major tag `vX`.
- The README shows both `@v1` and full-SHA pinning.

## Verify

`yamllint --strict action.yaml && actionlint`; behavior is proven by `_job-self-test.yaml` in CI.
