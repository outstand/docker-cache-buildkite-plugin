#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load '../lib/shared'

override_file1=$(cat <<-EOF
services:
  docker-cache-buildkite-plugin:
    image: alpine:latest
    volumes:
      - bundler-data:/volumes/bundler-data
      - yarn-data:/volumes/yarn-data
EOF
)

@test "Generate volume override" {
  run build_volume_override_file "bundler-data" "yarn-data"

  assert_success
  assert_output "$override_file1"
}
