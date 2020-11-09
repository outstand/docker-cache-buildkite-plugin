#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

# export BUILDKITE_AGENT_STUB_DEBUG=/dev/stdout
# export AWS_STUB_DEBUG=/dev/stdout
# export BATS_MOCK_TMPDIR=$PWD

teardown() {
  docker-compose -f tests/fixtures/docker-compose.yml -p buildkite1111 down -v
  rm -f docker-compose.cache-volumes.buildkite-1-override.yml
  rm -rf cache
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

@test "Save: Persists cache to S3" {
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

  stub buildkite-agent \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \
    "meta-data get docker-compose-project-name : echo buildkite1111"

  stub aws \
    "s3api head-object --bucket bucket --key slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar : exit 1" \
    "s3 cp v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar s3://bucket/slug/pipeline/v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0.tar : echo Copied to S3"

  # Populate docker volumes
  build_volume_override_file bundler-data yarn-data | tee docker-compose.cache-volumes.buildkite-1-override.yml

  docker-compose \
    -f tests/fixtures/docker-compose.yml \
    -f docker-compose.cache-volumes.buildkite-1-override.yml \
    -p buildkite1111 \
    run --rm \
    -w /volumes/bundler-data \
    docker-cache-buildkite-plugin \
    sh -c "echo bundler > /volumes/bundler-data/bundler.txt"

  docker-compose \
    -f tests/fixtures/docker-compose.yml \
    -f docker-compose.cache-volumes.buildkite-1-override.yml \
    -p buildkite1111 \
    run --rm \
    -w /volumes/yarn-data \
    docker-cache-buildkite-plugin \
    sh -c "echo yarn > /volumes/yarn-data/yarn.txt"

  run "$PWD/hooks/post-command"

  assert_success
  assert_output --partial "Using cache key: v1-bundler-cache-linux-x86_64-d958fad66a3456aa1f7b9e492063ed3de2baabb0"
  assert_output --partial "Saving cache"

  unstub aws
  unstub buildkite-agent
}
