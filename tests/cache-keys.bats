#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'
load '../lib/cache-keys'

@test "Cache keys: Find key based on prefix" {
  bucket=outstand-buildkite-cache
  prefix=outstand/docker-cache-buildkite-plugin/fixtures
  run find_cache "$bucket" "$prefix" "v1-bundler-cache-"

  assert_success
  assert_output "v1-bundler-cache-linux-x86_64-da39a3ee5e6b4b0d3255bfef95601890afd80709-9cf9e79ffe0d01c9e3d6a143ac63a9c9ecc8015b"
}

@test "Cache keys: Reports on failure" {
  bucket=outstand-buildkite-cache
  prefix=outstand/docker-cache-buildkite-plugin/fixtures

  stub docker \
    "build --pull -t docker-cache-buildkite-plugin:find-cache /plugin/ruby : echo FAILURE; exit 1"

  run find_cache "$bucket" "$prefix" "v1-bundler-cache-"

  assert_failure
  assert_output <<OUTPUT
docker build failed:
FAILURE
OUTPUT
}
