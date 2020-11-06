#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

override_file1=$(cat <<-EOF
version: '3.8'
services:
  docker-cache-buildkite-plugin:
    image: alpine:latest
    volumes:
      - bundler-data:/volumes/bundler-data
      - yarn-data:/volumes/yarn-data
EOF
)

@test "Generate volume override" {
  run build_volume_override_file_with_version "3.8" "bundler-data" "yarn-data"

  assert_success
  assert_output "$override_file1"
}

@test "Detect compose version" {
  stub buildkite-agent \
    "meta-data get docker-compose-config-files : echo tests/fixtures/docker-compose.yml" \

  run docker_compose_config_version

  assert_success
  assert_output "3.3"

  unstub buildkite-agent
}
