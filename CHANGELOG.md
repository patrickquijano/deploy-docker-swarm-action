# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-10-20

### Changed

- Rename the action's display name from `Deploy Docker Swarm stack` to `Deploy Docker Swarm Action`, as shown on GitHub Marketplace and in workflow run logs. The `uses:` path is unchanged.

## [0.1.0] - 2026-10-20

### Added

- Composite action that deploys a Compose file as a Docker Swarm stack to a remote manager over `ssh://`, `tcp://` or `unix://` (`docker-host`, `stack-name`, `compose-file`), always detached and with `--with-registry-auth`.
- SSH transport with host key checking always on: `ssh-known-hosts` is required for `ssh://` hosts, `ssh-private-key` is masked and kept in a per-run directory, `ssh-connect-timeout` defaults to 30 seconds, and `~/.ssh` is never touched.
- `ssh-proxy-command` input to reach the manager through a `ProxyCommand`, for example a Cloudflare Tunnel with `cloudflared access ssh`.
- Every input is validated before anything is created, and the action checks that the host is reachable and is a Swarm manager before it logs in or deploys. Failures are reported as `::error::` annotations.
- `env-file` input: `KEY=VALUE` lines that are parsed (never sourced) and exported for Compose interpolation. Names that would redirect the deploy or the action itself (`PATH`, `IFS`, `HOME`, `LD_*`, `DOCKER_*`, `SWARM_*`, `GITHUB_*`, `RUNNER_*`, `INPUT_*`) are rejected.
- `services` input to deploy only some services, and `prune` input to remove stack services that are no longer in the Compose file. The two cannot be combined.
- Optional registry login (`registry`, `registry-username`, `registry-password`) with a masked password passed on stdin, and a logout that runs even when an earlier step fails.
- Image cleanup after the deploy (`keep-images`, default `3`): keeps the newest N images per repository of the stack on the manager, skips images used by containers, then runs `docker image prune -f`, which removes all dangling images on the manager. Set `keep-images: ""` to skip it.
- Teardown that always removes the temporary Docker context and the per-run directory.
- MIT license.

[unreleased]: https://github.com/patrickquijano/deploy-docker-swarm-action/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/patrickquijano/deploy-docker-swarm-action/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/patrickquijano/deploy-docker-swarm-action/releases/tag/v0.1.0
