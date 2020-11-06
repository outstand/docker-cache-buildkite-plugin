#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

# export BUILDKITE_AGENT_STUB_DEBUG=/dev/stdout
# export AWS_STUB_DEBUG=/dev/stdout
# export BATS_MOCK_TMPDIR=$PWD

teardown() {
  docker-compose -f tests/fixtures/docker-compose.yml -p buildkite1111 down -v
}

@test "Correctly expands cache key and skips on cache miss" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  stub aws \
    "s3api head-object --bucket bucket --key slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar : exit 1"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Using cache key: v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0"
  assert_output --partial "Cache restore is skipped"

  unstub aws
}

@test "Uses a volume override file on cache hit" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  stub buildkite-agent \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \
    "meta-data get docker-compose-project-name : echo buildkite1111"

  stub aws \
    "s3api head-object --bucket bucket --key slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar : exit 0" \
    "s3 cp s3://bucket/slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar . : cp tests/fixtures/cache.tar ./v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar; echo Copied from S3"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Cache hit"
  assert_output --partial "Copied from S3"
  assert_output asdfasdf

  unstub buildkite-agent
  unstub aws
}
