#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

function find_cache() {
  local bucket="$1"
  local prefix="$2"
  shift
  shift

  keys=("${@}")

  if ! output=$(docker build --pull -t docker-cache-buildkite-plugin:find-cache "${BASEDIR}/ruby" 2>&1); then
    >&2 echo "docker build failed:"
    >&2 echo "${output}"
    exit 2
  fi

  env_vars=()
  env_vars+=("-e" "AWS_VAULT=${AWS_VAULT:-}")
  env_vars+=("-e" "AWS_REGION=${AWS_REGION:-}")
  env_vars+=("-e" "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}")
  env_vars+=("-e" "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}")
  env_vars+=("-e" "AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-}")
  env_vars+=("-e" "AWS_SECURITY_TOKEN=${AWS_SECURITY_TOKEN:-}")
  env_vars+=("-e" "AWS_SESSION_EXPIRATION=${AWS_SESSION_EXPIRATION:-}")
  if [[ -n "${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI:-}" ]]; then
    env_vars+=("-e" "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI}")
  fi

  docker \
    --log-level "error" \
    run \
    --rm \
    "${env_vars[@]}" \
    docker-cache-buildkite-plugin:find-cache \
    ruby -I . cli.rb \
    "$bucket" "$prefix" "${keys[@]}"
}
