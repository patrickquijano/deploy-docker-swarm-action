#!/usr/bin/env bats
load helpers

# Runs the `setup` and `teardown` step scripts extracted from action.yaml.
setup() {
	setup_stubs
	cd "$ROOT" || return 1
	export GITHUB_RUN_ID=1 GITHUB_RUN_ATTEMPT=1
	export INPUT_DOCKER_HOST=ssh://runner@localhost
	export INPUT_SSH_KNOWN_HOSTS="localhost ssh-ed25519 AAAAdummy"
	export INPUT_STACK_NAME=test-setup
	export INPUT_COMPOSE_FILE=tests/fixtures/compose.yaml
	yq '.runs.steps[] | select(.id == "setup") | .run' action.yaml >"$BATS_TEST_TMPDIR/setup.sh"
	yq '.runs.steps[] | select(.id == "teardown") | .run' action.yaml >"$BATS_TEST_TMPDIR/teardown.sh"
}

work_dirs() {
	find "$RUNNER_TEMP" -maxdepth 1 -name 'deploy-swarm.*'
}

@test "rejects prune combined with services" {
	INPUT_SERVICES=web INPUT_PRUNE=true run sh "$BATS_TEST_TMPDIR/setup.sh"
	[ "$status" -eq 1 ]
	[[ "$output" == *"::error::prune cannot be combined with services"* ]]
	[ -z "$(work_dirs)" ]
}

@test "rejects a reserved env-file key" {
	echo 'DOCKER_HOST=tcp://example.invalid:2375' >"$BATS_TEST_TMPDIR/reserved.env"
	INPUT_ENV_FILE="$BATS_TEST_TMPDIR/reserved.env" run sh "$BATS_TEST_TMPDIR/setup.sh"
	[ "$status" -eq 1 ]
	[[ "$output" == *"reserved variable name 'DOCKER_HOST'"* ]]
	[ -z "$(work_dirs)" ]
}

@test "fails on an unreachable host, enforces host keys and tears down" {
	STUB_FAIL_ON=version run sh "$BATS_TEST_TMPDIR/setup.sh"
	[ "$status" -eq 1 ]
	[[ "$output" == *"::error::cannot reach the Docker host"* ]]
	work_dir=$(work_dirs)
	grep -q '^  StrictHostKeyChecking yes$' "$work_dir/ssh_config"
	grep -q "^  UserKnownHostsFile $work_dir/known_hosts\$" "$work_dir/ssh_config"

	SWARM_CONTEXT=$(sed -n 's/^context=//p' "$GITHUB_OUTPUT")
	SWARM_WORK_DIR=$(sed -n 's/^work-dir=//p' "$GITHUB_OUTPUT")
	export SWARM_CONTEXT SWARM_WORK_DIR
	run sh "$BATS_TEST_TMPDIR/teardown.sh"
	[ "$status" -eq 0 ]
	grep -q "^docker context rm -f $SWARM_CONTEXT\$" "$STUB_LOG"
	[ -z "$(work_dirs)" ]
}

@test "fails when the host is not a Swarm manager" {
	STUB_MANAGER=false run sh "$BATS_TEST_TMPDIR/setup.sh"
	[ "$status" -eq 1 ]
	[[ "$output" == *"::error::the Docker host is not a Swarm manager node"* ]]
}
