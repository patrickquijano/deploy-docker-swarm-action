# shellcheck shell=bash
# Shared bats setup: fake docker and ssh first on PATH, logging argv and stdin.

setup_stubs() {
	ROOT=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
	export ROOT
	export STUB_LOG="$BATS_TEST_TMPDIR/calls.log"
	export STUB_STDIN="$BATS_TEST_TMPDIR/stdin.log"
	export RUNNER_TEMP="$BATS_TEST_TMPDIR/runner"
	export GITHUB_OUTPUT="$BATS_TEST_TMPDIR/output"
	mkdir -p "$RUNNER_TEMP" "$BATS_TEST_TMPDIR/stubs"
	: >"$STUB_LOG"
	: >"$STUB_STDIN"
	: >"$GITHUB_OUTPUT"

	cat >"$BATS_TEST_TMPDIR/stubs/docker" <<'STUB'
#!/bin/sh
echo "docker $*" >>"$STUB_LOG"
if [ -n "${STUB_FAIL_ON:-}" ]; then
  case "$*" in
    *"$STUB_FAIL_ON"*)
      echo "stub failure" >&2
      exit 1
      ;;
  esac
fi
case "$*" in
  *"--password-stdin"* | *"stack deploy -c -"*) cat >>"$STUB_STDIN" ;;
esac
case "$*" in
  *"config --services"*) printf '%s\n' "${STUB_SERVICES:-web api}" | tr ' ' '\n' ;;
  *"config --images"*) printf '%s\n' ${STUB_IMAGES:-} ;;
  *"compose "*" config "*) echo "COMPOSE_CONFIG" ;;
  *"info --format"*) echo "${STUB_MANAGER:-true}" ;;
  *"ps -a"*) printf '%s\n' ${STUB_PS:-} ;;
  *"image inspect"*)
    for last; do :; done
    echo "$last"
    ;;
  *"image ls"*) printf '%s\n' "${STUB_IMAGE_LS:-}" ;;
esac
STUB
	cat >"$BATS_TEST_TMPDIR/stubs/ssh" <<'STUB'
#!/bin/sh
echo "ssh $*" >>"$STUB_LOG"
STUB
	chmod +x "$BATS_TEST_TMPDIR/stubs/"*
	export PATH="$BATS_TEST_TMPDIR/stubs:$PATH"
}
