---
paths:
  - tests/**
  - .github/workflows/**
---

# Testing

## Unit tests (bats)

- Use bats only for inline workflow and action steps, such as `tests/check-release.bats` and `tests/setup.bats` (the step script is extracted with `yq`).
- Put negative cases in bats, not the self-test: a failing `uses:` step leaves error annotations on a green run, even with `continue-on-error`.
- Stub `docker` and `ssh` with fake executables placed first on `PATH`.

## Self-test (`.github/workflows/_job-self-test.yaml`)

- Run `docker swarm init` on the runner.
- Call `uses: ./` with a fixture compose file.
- Assert with `docker stack services` or `docker service ls`, and on the action outputs.

## Verify

`shellcheck tests/*.bats tests/helpers.bash && shfmt -d tests && bats tests/`; the self-test runs only in CI.
