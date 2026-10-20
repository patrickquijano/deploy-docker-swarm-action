# Deploy Docker Swarm Action

Deploy a Compose file as a Docker Swarm stack over SSH from a GitHub Actions workflow.

It is a composite GitHub Action that runs against a remote Swarm manager, so a workflow can ship a stack without a hand-built SSH session.

It creates a temporary Docker context to the manager over SSH (optionally through a Cloudflare Tunnel), `tcp://` or `unix://`. Through that context it logs in to a registry if configured, runs `docker stack deploy`, keeps the newest N images of the stack's repositories, logs out and removes the context.

> **Status:** pre-release. No version is tagged yet, so the `@v1` references below resolve only once `v1` is published, and the interface may still change.

## Contents

- [Compatibility](#compatibility)
- [Install](#install)
- [Usage](#usage)
- [Components](#components)
- [Configuration](#configuration)
- [Behavior](#behavior)
- [Development](#development)
- [Releasing](#releasing)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

## Compatibility

Runs on GitHub-hosted or self-hosted runners that provide a POSIX `sh`, the `docker` CLI with the Compose v2 plugin and, for `ssh://` hosts, an `ssh` client. The self-test runs on `ubuntu-24.04`. The target host must be a Swarm manager node.

## Install

There is nothing to install. Reference the action from a workflow step:

```yaml
- uses: patrickquijano/deploy-docker-swarm-action@v1
```

Pin to a full commit SHA for a supply-chain-safe reference:

```yaml
- uses: patrickquijano/deploy-docker-swarm-action@<full-commit-sha> # <version-tag>
```

Replace `<full-commit-sha>` with the commit of the release you want and `<version-tag>` with its tag.

## Usage

```yaml
- uses: actions/checkout@v7
- uses: patrickquijano/deploy-docker-swarm-action@v1
  with:
    docker-host: ssh://deploy@swarm.example.com
    ssh-private-key: ${{ secrets.SWARM_SSH_KEY }}
    ssh-known-hosts: ${{ vars.SWARM_KNOWN_HOSTS }}
    stack-name: myapp
    compose-file: compose.yaml
```

The step deploys the stack `myapp` from `compose.yaml` and fails with an `::error::` annotation if the host is not a reachable Swarm manager.

Environment variables set on the calling step (`env:`) are visible to the deploy and are used when the Compose file is interpolated.

### Cloudflare Tunnel

The runner needs `cloudflared` on its `PATH` before this step.

```yaml
- uses: patrickquijano/deploy-docker-swarm-action@v1
  with:
    docker-host: ssh://deploy@swarm.example.com
    ssh-private-key: ${{ secrets.SWARM_SSH_KEY }}
    ssh-known-hosts: ${{ vars.SWARM_KNOWN_HOSTS }}
    ssh-proxy-command: cloudflared access ssh --hostname %h
    stack-name: myapp
```

### Registry login, service subset and prune

```yaml
- uses: patrickquijano/deploy-docker-swarm-action@v1
  with:
    docker-host: ssh://deploy@swarm.example.com
    ssh-private-key: ${{ secrets.SWARM_SSH_KEY }}
    ssh-known-hosts: ${{ vars.SWARM_KNOWN_HOSTS }}
    stack-name: myapp
    registry: ghcr.io
    registry-username: ${{ github.actor }}
    registry-password: ${{ secrets.GITHUB_TOKEN }}
    services: web api
    keep-images: '5'
```

## Components

The action runs these composite steps in order. Each step's logic is inline in [`action.yaml`](action.yaml).

| Step             | Purpose                                                                                         |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| `setup`          | Validate inputs, mask secrets, create the SSH directory and Docker context, probe the manager.  |
| `login`          | Log in to the registry with the password on stdin. Runs only when a username is set.            |
| `deploy`         | Run `docker stack deploy`, optionally for a service subset and with `--prune`.                  |
| `cleanup-images` | Keep the newest `keep-images` images per repository. Runs only when `keep-images` is non-empty. |
| `logout`         | Log out of the registry. Runs even when an earlier step fails.                                  |
| `teardown`       | Remove the Docker context and the per-run directory. Always runs.                               |

### Workflows and tests

The `_job-*` files are reusable workflows that `ci.yaml` and `release.yaml` call.

| File                                                | Purpose                                                                                                    |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `.github/workflows/ci.yaml`                         | Runs `lint` and `self-test` on pull requests and pushes to `main`.                                         |
| `.github/workflows/release.yaml`                    | On a `vX.Y.Z` tag: lint, self-test, Marketplace readiness, draft release. On publish: moves the major tag. |
| `.github/workflows/_job-lint.yaml`                  | Runs `actionlint`, `shellcheck`, `shfmt` and `bats`.                                                       |
| `.github/workflows/_job-self-test.yaml`             | Runs the action with `uses: ./` against a swarm created by `docker swarm init` on the runner.              |
| `.github/workflows/_job-marketplace-readiness.yaml` | Checks `action.yaml`, the CHANGELOG section and the tag; outputs the release notes and major tag.          |
| `.github/workflows/_job-draft-release.yaml`         | Creates the draft GitHub release.                                                                          |
| `.github/workflows/_job-move-major-tag.yaml`        | Moves the major tag (for example `v1`) to the published release.                                           |
| `tests/check-release.bats`                          | Bats tests for the Marketplace readiness step, with fixtures in `tests/fixtures/`.                         |

## Configuration

The action is configured through these inputs, set with `with:`.

| Input                 | Required | Default        | Description                                                                                                                                                                                                                          |
| --------------------- | -------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `docker-host`         | yes      |                | `ssh://user@host[:port]`, `tcp://…` or `unix://…`. `tcp://` and `unix://` are passed through as-is.                                                                                                                                  |
| `ssh-private-key`     | no       |                | Private key for `ssh://` hosts. Masked, written with mode 0600 to a per-run directory.                                                                                                                                               |
| `ssh-known-hosts`     | ssh only |                | known_hosts lines for the manager. Required for `ssh://`; host key checking is always on.                                                                                                                                            |
| `ssh-proxy-command`   | no       |                | SSH `ProxyCommand`, for example `cloudflared access ssh --hostname %h`.                                                                                                                                                              |
| `ssh-connect-timeout` | no       | `30`           | SSH `ConnectTimeout` in seconds.                                                                                                                                                                                                     |
| `stack-name`          | yes      |                | Stack name, matching `^[a-zA-Z0-9][a-zA-Z0-9_.-]*$`.                                                                                                                                                                                 |
| `compose-file`        | no       | `compose.yaml` | Path to the Compose file. Must exist.                                                                                                                                                                                                |
| `env-file`            | no       |                | `KEY=VALUE` lines exported before the deploy. `#` comments and blank lines are skipped. Parsed, never sourced. Reserved names are rejected: `PATH`, `IFS`, `HOME`, `LD_*`, `DOCKER_*`, `SWARM_*`, `GITHUB_*`, `RUNNER_*`, `INPUT_*`. |
| `services`            | no       |                | Whitespace or comma separated services to deploy. Each must exist in the Compose file.                                                                                                                                               |
| `prune`               | no       | `false`        | `true` removes stack services that are no longer in the file. Rejected together with `services`.                                                                                                                                     |
| `registry`            | no       |                | Registry to log in to. Empty means Docker Hub.                                                                                                                                                                                       |
| `registry-username`   | no       |                | Login runs only when username and password are both set; one without the other is an error.                                                                                                                                          |
| `registry-password`   | no       |                | Password or token. Masked and passed with `--password-stdin`.                                                                                                                                                                        |
| `keep-images`         | no       | `3`            | Non-negative integer. Empty skips the image cleanup.                                                                                                                                                                                 |

The action has no outputs.

## Behavior

- Every input is validated before anything is created. Any error stops the run with `::error::` and a failing exit code.
- Right after the context is created the action checks that the host is reachable and a Swarm manager. An unreachable host, an authentication failure or a worker node fails there, before login or deploy.
- SSH state lives in a per-run directory under `$RUNNER_TEMP` with an `ssh` shim that uses its own config. `~/.ssh` is never touched.
- The deploy is always detached (`--detach=true`) and uses `--with-registry-auth`. Deploys are idempotent.
- With `services`, the action renders `docker compose config <services>` and pipes it to `docker stack deploy -c -`.
- Logout and teardown run even when an earlier step fails, and never hide the original failure.

### Image cleanup

After the deploy, for each repository referenced by the Compose file, the action keeps the newest `keep-images` images and removes the rest on the manager node. It leaves out images that existing containers use and never forces a removal; a failed `docker image rm` fails the step. It then runs `docker image prune -f`, which removes **all** dangling images on the manager, not only the stack's. Worker nodes are not cleaned. Set `keep-images: ""` to skip the cleanup.

## Development

Prerequisites: `bash` (for bats), Node.js with npm (Husky and commit checks), and the tools below.

```sh
npm install
brew install bats-core shellcheck shfmt actionlint yamllint yq
actionlint
shellcheck tests/*.bats tests/helpers.bash
shfmt -d tests
yamllint --strict action.yaml .github tests/fixtures
bats tests/
```

To run the CI lint job locally with [`act`](https://github.com/nektos/act):

```sh
act pull_request -W .github/workflows/ci.yaml -j lint
```

`.actrc` sets the runner image, the `linux/amd64` architecture and the offline action cache. `act` uses `/var/run/docker.sock`; for Colima or another Docker context, point it at that daemon:

```sh
DOCKER_HOST="$(docker context inspect -f '{{.Endpoints.docker.Host}}')" act pull_request -W .github/workflows/ci.yaml -j lint
```

The `self-test` job runs only in CI: it needs `sshd` under systemd and runs `docker swarm init`, so `.actrc` does not give the job container the host Docker socket.

## Releasing

1. Move the `[Unreleased]` entries in `CHANGELOG.md` under a `## [X.Y.Z]` heading and merge to `main`.
2. Create and push a signed tag: `git tag -s vX.Y.Z -m vX.Y.Z && git push origin vX.Y.Z`.
3. The `release` workflow runs the tests, checks Marketplace readiness and creates a draft release with the changelog section as notes.
4. Publish the draft from the Releases page with **Publish this Action to the GitHub Marketplace** ticked. GitHub has no API for that checkbox.
5. Publishing a non-prerelease moves the major tag (`v1`) to the release.

## Contributing

Commits follow Conventional Commits and are signed; the `commit-msg` hook enforces this. Run the checks above before opening a pull request.

## Support

Open an issue at [github.com/patrickquijano/deploy-docker-swarm-action/issues](https://github.com/patrickquijano/deploy-docker-swarm-action/issues).

## License

[MIT](LICENSE) © Patrick Quijano
