#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

# export BUILDKITE_AGENT_STUB_DEBUG=/dev/stdout
# export AWS_STUB_DEBUG=/dev/stdout
# export BATS_MOCK_TMPDIR=$PWD
# export FIND_CACHE_STUB_DEBUG=/dev/stdout

teardown() {
  docker-compose -f tests/fixtures/docker-compose.yml -p buildkite1111 down -v
  rm -f docker-compose.cache-volumes.buildkite-1-override.yml
  rm -rf cache
}

@test "Restore: Correctly expands cache key and skips on cache miss" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}-'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  stub find_cache \
    "bucket slug/pipeline v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0 v1-bundler-cache-linux-x86_64- : exit 1"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Restoring Docker Cache"
  assert_output --partial "Cache restore is skipped because s3://bucket/slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0 does not exist"

  unstub find_cache
}

@test "Restore: Uses name if set" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_NAME=bundler-cache
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}-'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  stub find_cache \
    "bucket slug/pipeline v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0 v1-bundler-cache-linux-x86_64- : exit 1"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_line --regexp "Restoring Docker Cache: .*bundler-cache.*"
  assert_output --partial "Cache restore is skipped because s3://bucket/slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0 does not exist"

  unstub find_cache
}

@test "Restore: Uses a volume override file on cache hit" {
  export BUILDKITE_JOB_ID=1111
  export BUILDKITE_BUILD_NUMBER=1
  export BUILDKITE_ORGANIZATION_SLUG=slug
  export BUILDKITE_PIPELINE_SLUG=pipeline
  export BUILDKITE_PLUGIN_DOCKER_CACHE_S3_BUCKET=bucket
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_0='v1-bundler-cache-{{ arch }}-{{ checksum "tests/fixtures/lockfile" }}'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_KEYS_1='v1-bundler-cache-{{ arch }}-'
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_0=bundler-data
  export BUILDKITE_PLUGIN_DOCKER_CACHE_VOLUMES_1=yarn-data

  export DOCKER_COMPOSE_CONFIG_FILES="tests/fixtures/docker-compose.yml"
  export DOCKER_COMPOSE_PROJECT_NAME="buildkite1111"

  stub find_cache \
    "bucket slug/pipeline v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0 v1-bundler-cache-linux-x86_64- : echo v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0; exit 0"

  stub aws \
    "s3 cp s3://bucket/slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar . : cp tests/fixtures/cache.tar ./v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar; echo Copied from S3"

  run "$PWD/hooks/pre-command"

  assert_success
  assert_output --partial "Cache hit"
  assert_output --partial "Copied from S3"

  unstub aws
  unstub find_cache

  run docker-compose \
    -f tests/fixtures/docker-compose.yml \
    -f docker-compose.cache-volumes.buildkite-1-override.yml \
    -p buildkite1111 \
    run --rm \
    -w /volumes/bundler-data \
    docker-cache-buildkite-plugin \
    ls

  assert_output --partial bundler.txt

  run docker-compose \
    -f tests/fixtures/docker-compose.yml \
    -f docker-compose.cache-volumes.buildkite-1-override.yml \
    -p buildkite1111 \
    run --rm \
    -w /volumes/yarn-data \
    docker-cache-buildkite-plugin \
    ls

  assert_output --partial yarn.txt
}
