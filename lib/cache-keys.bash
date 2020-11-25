#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

function find_cache() {
  local bucket="$1"
  local prefix="$2"
  shift
  shift

  keys=("${@}")

  output=$(docker build --pull -t docker-cache-buildkite-plugin:find-cache "${BASEDIR}/ruby" 2>&1)

  if [[ $? != 0 ]]; then
    >&2 echo "docker build failed:"
    >&2 echo "${output}"
    exit 2
  fi

  docker \
    --log-level "error" \
    run \
    --rm \
    -e AWS_VAULT=${AWS_VAULT:-} \
    -e AWS_REGION=${AWS_REGION:-} \
    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-} \
    -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-} \
    -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-} \
    -e AWS_SECURITY_TOKEN=${AWS_SECURITY_TOKEN:-} \
    -e AWS_SESSION_EXPIRATION=${AWS_SESSION_EXPIRATION:-} \
    docker-cache-buildkite-plugin:find-cache \
    ruby -I . cli.rb \
    "$bucket" "$prefix" "${keys[@]}"
}
