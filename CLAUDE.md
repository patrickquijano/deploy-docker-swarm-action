# deploy-docker-swarm-action

## Overview

A composite GitHub Action that deploys a Compose file as a Docker Swarm stack over SSH.

## Architecture

Layout:

- `action.yaml`: the public contract (inputs, outputs, composite steps).
- `tests/check-release.bats`: bats test for the release workflow step.
- `tests/setup.bats`: bats tests for the `setup` and `teardown` steps of `action.yaml`, extracted with `yq`; holds the negative cases. Fixtures live in `tests/fixtures/`; `_job-self-test.yaml` uses them too.
- `.github/workflows/ci.yaml`: runs on `pull_request` and on `push` to main, and calls `_job-lint.yaml` and `_job-self-test.yaml`.
- `.github/workflows/_job-*.yaml`: one call-only job per file (`on: workflow_call`).
  - `_job-lint.yaml`: `actionlint`, `shellcheck`, `shfmt` and `bats`.
  - `_job-self-test.yaml`: self-test with `uses: ./` against a swarm created by `docker swarm init` on the runner.
  - `_job-marketplace-readiness.yaml`: Marketplace readiness check; its inline step also outputs the release notes and major tag.
  - `_job-draft-release.yaml` and `_job-move-major-tag.yaml`: create the draft release and move the major tag.
- `.github/workflows/release.yaml`: on a `vX.Y.Z` tag push, runs lint, self-test and marketplace readiness, then creates a draft release; on a published release, moves the major tag.
- `.actrc`: `act` defaults (amd64, pinned runner image, offline action cache, no host Docker socket).
- `.husky/` and `.commitlintrc.json`: commit checks (see `.claude/rules/commits.md`).

Flow: workflow → `action.yaml` inputs → env vars → `setup` (validates every input, parses the env file into `$SWARM_WORK_DIR/env`, creates an isolated SSH dir and a Docker context, probes the manager) → `DOCKER_CONTEXT` → `login`, `deploy`, `cleanup-images`, `logout` → `teardown` (always).

Later steps trust `setup` and keep only their docker calls. Each defines at most a one-line `fail` helper, requires `DOCKER_CONTEXT` and sources `$SWARM_WORK_DIR/env`.

## Commands

- `actionlint`: lint `action.yaml` and workflows.
- `shellcheck tests/*.bats tests/helpers.bash`: lint the test shell code. CI does not lint the inline step code.
- `shfmt -d tests`: check shell formatting.
- `yamllint --strict action.yaml .github tests/fixtures`: lint YAML (config in `.yamllint.yaml`, aligned with the repo formatter).
- `bats tests/`: run the release-step and setup-step tests (install with `brew install bats-core`).
- `npx prettier --check "*.md" ".claude/**/*.md" .github/*.md`: check Markdown formatting (config in `.prettierrc.json`).
- `npx markdownlint-cli2 "*.md" ".claude/**/*.md" ".github/*.md"`: lint Markdown (config in `.markdownlint-cli2.jsonc`).
- `act pull_request -W .github/workflows/ci.yaml -j lint`: run the lint job locally. On Colima or another Docker context, prefix `DOCKER_HOST="$(docker context inspect -f '{{.Endpoints.docker.Host}}')"`.

## Precedence

- Order: user request > path-scoped rule > this file > unconditional rules > skill defaults.
- On a conflict, ask.
- Trade-offs: correctness > security > clarity > simplicity > maintainability > testability > performance.
- `.claude/rules/commits.md` beats the session commit-attribution trailer: no `Claude-Session:` line.

## Boundaries

Never:

- Print or log SSH private keys, registry passwords or `DOCKER_HOST` credentials.
- Run `docker swarm leave --force`, `docker stack rm` or `docker system prune` against a non-local host.

Ask first:

- Push.
- Create or move tags, including `v1`.
- Publish a GitHub release or Marketplace listing.
- Rewrite history.
- Run `act` jobs that call `docker swarm init`, or re-enable the host Docker socket that `.actrc` turns off.

## Changes

- Change only what the task needs.
- An input or output change updates `action.yaml`, the README usage section and the tests in the same change.

## Definition of done

- `actionlint`, `shellcheck tests/*.bats tests/helpers.bash`, `shfmt -d tests`, `yamllint --strict action.yaml .github tests/fixtures`, `bats tests/`, the Markdown format and lint commands for any Markdown you changed, and the commit-msg hook all pass.
- The CI `ci.yaml` job is green on the PR.

## Maintenance

- Update this file and the rules in the same change that alters a command, path or convention.
- Record resolved recurring issues in auto memory as `- <symptom> → <fix>`, never in this file.
