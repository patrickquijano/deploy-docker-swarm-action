#!/usr/bin/env bats
load helpers

# A temp repo whose main branch holds a valid action.yaml and CHANGELOG.
setup() {
	setup_stubs
	REPO="$BATS_TEST_TMPDIR/repo"
	mkdir -p "$REPO"
	cd "$REPO" || return 1
	git init -q -b main
	git config user.email t@example.com
	git config user.name t
	git config commit.gpgsign false
	git config tag.gpgsign false
	cat >action.yaml <<'YML'
name: x
description: y
author: z
branding:
  icon: upload-cloud
  color: blue
YML
	cat >CHANGELOG.md <<'MD'
# Changelog

## [Unreleased]

## [1.2.3] - 2026-10-20

### Added

- A thing.

## [1.0.0] - 2026-01-01

- Old.

[unreleased]: https://example.com
MD
	git add -A
	git commit -q -m init
	export RELEASE_TAG=v1.2.3 RELEASE_BRANCH=main
}

# Run the inline step of _job-marketplace-readiness.yaml the way the runner does, under `sh -e`.
run_check() {
	yq '.jobs.check.steps[] | select(.id == "check") | .run' "$ROOT/.github/workflows/_job-marketplace-readiness.yaml" >"$BATS_TEST_TMPDIR/check.sh"
	run sh -e "$BATS_TEST_TMPDIR/check.sh"
}

# The `notes` output, delimited the way $GITHUB_OUTPUT multiline values are.
notes_output() {
	awk '/^notes<<NOTES_EOF_/ { on = 1; next } /^NOTES_EOF_/ { on = 0 } on' "$GITHUB_OUTPUT"
}

commit_all() {
	git add -A
	git commit -q -m change
}

@test "valid tag outputs the notes and the major tag" {
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 0 ]
	grep -qx "major=v1" "$GITHUB_OUTPUT"
	notes=$(notes_output)
	[ "$(printf '%s\n' "$notes" | head -1)" = "### Added" ]
	printf '%s\n' "$notes" | grep -qx -- "- A thing."
	run grep -c -e Old -e example.com <<<"$notes"
	[ "$output" = 0 ]
}

@test "rejects a tag that is not vX.Y.Z" {
	export RELEASE_TAG=v1.2.3-rc.1
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"is not vX.Y.Z"* ]]
}

@test "rejects a missing CHANGELOG section" {
	export RELEASE_TAG=v2.0.0
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"## [2.0.0]"* ]]
}

@test "rejects an empty CHANGELOG section" {
	printf '## [3.0.0] - 2026-10-20\n\n## [1.2.3] - 2026-10-20\n' >>CHANGELOG.md
	commit_all
	export RELEASE_TAG=v3.0.0
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"## [3.0.0]"* ]]
}

@test "rejects action.yaml without branding" {
	printf 'name: x\ndescription: y\nauthor: z\n' >action.yaml
	commit_all
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"branding"* ]]
}

@test "rejects a duplicate action.yml" {
	cp action.yaml action.yml
	commit_all
	git tag "$RELEASE_TAG"
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"action.yml"* ]]
}

@test "rejects a tag that is not on the release branch" {
	git checkout -q -b side
	echo more >>CHANGELOG.md
	commit_all
	git tag "$RELEASE_TAG"
	git checkout -q main
	run_check
	[ "$status" -eq 1 ]
	[[ $output == *"is not on main"* ]]
}
