---
paths:
  - tests/**
  - .github/workflows/**
---

# Testing

## Unit tests (bats)

- Use bats only for inline workflow steps, such as `tests/check-release.bats`.
- Stub `docker` and `ssh` with fake executables placed first on `PATH`.

## Self-test (`.github/workflows/_job-self-test.yaml`)

- Run `docker swarm init` on the runner.
- Call `uses: ./` with a fixture compose file.
- Assert with `docker stack services` or `docker service ls`, and on the action outputs.
- Add a negative case with `continue-on-error: true` and assert `steps.<id>.outcome == 'failure'`.

## Verify

`shellcheck tests/*.bats tests/helpers.bash && shfmt -d tests && bats tests/`; the self-test runs only in CI.
