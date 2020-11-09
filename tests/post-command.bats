#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

teardown() {
  docker-compose -f tests/fixtures/docker-compose.yml -p buildkite1111 down -v
}

@test "Save: Skips if save is not set" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "Skipping cache save; save not set"
}

@test "Save: Correctly expands cache key and skips on existing cache" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_SAVE=1

  stub aws \
    "s3api head-object --bucket bucket --key slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar : exit 0"

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "Using cache key: v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0"
  assert_output --partial "Skipping cache save; cache already exists"

  unstub aws
}
