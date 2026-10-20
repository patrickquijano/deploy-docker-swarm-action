# Principles

- Simplicity: the action stays a thin wrapper over the `docker` CLI.
- Structure: `action.yaml` holds wiring; step logic is inline in `action.yaml` and workflow `run:` steps, with no external scripts.
- Behavior: fail fast with `set -eu`.
- Portability: those steps are POSIX `sh`.
- Behavior: deploys are idempotent, so re-running `docker stack deploy` is safe.
- Behavior: inputs and outputs stay backward compatible within a major version; a breaking change needs a new major.
- Security: mask every secret with `::add-mask::`.
- Security: verify `known_hosts`; never set `StrictHostKeyChecking=no`.
- Security: give tokens least privilege.
- Validation: the setup step validates every input.
- Reliability: set SSH `ConnectTimeout`.
- Testing: new action behavior gets a `_job-self-test.yaml` assertion.
- Observability: use `::group::`, `::error::` and `::notice::`.
- Operations: config comes from inputs or env vars, never hard-coded.
- Patterns: add one only for a problem the code shows now; name the problem in the PR description or a code comment.
- Maintainability: tidy only lines the change already edits; record larger cleanups as GitHub issues (tech debt).
- Avoid: overengineering, forced patterns, excessive indirection, hidden dependencies, unnecessary dependencies, premature optimization.
- Verify: run the commands in CLAUDE.md `Definition of done`.
