## Summary

<!-- What changes and why. Name the problem any new pattern solves. Link issues with "Closes #123". -->

## Changes

<!-- One bullet per logical change. -->

-

## Testing

<!-- How you verified it: `_job-self-test.yaml` assertions, manual runs. -->

## Checklist

- [ ] Commits follow Conventional Commits, are signed and contain no attribution
- [ ] `actionlint`, `shellcheck`, `shfmt -d tests` and `bats tests/` pass
- [ ] New action behavior has a `_job-self-test.yaml` assertion
- [ ] An input or output change updates `action.yaml`, the README usage section and the tests
- [ ] Inputs stay backward compatible within the major version, or this is flagged as breaking
- [ ] No secrets, SSH keys or registry passwords are printed, logged or committed
