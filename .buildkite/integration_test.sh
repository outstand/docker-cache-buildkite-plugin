#!/bin/bash

set -euo pipefail

compose_params=()
while IFS=$' ' read -r file ; do
  [[ -n "${file:-}" ]] && compose_params+=(-f "$file")
done <<< "${DOCKER_COMPOSE_CONFIG_FILES:-}"

if [[ -n "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE:-}" ]] ; then
  compose_params+=(-f "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE}")
fi

compose_params+=(-p "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_PROJECT_NAME}")

if [[ "${1:-}" = "populate" ]]; then
  echo "--- Populate cache"

  number=$RANDOM
  echo "Using random number: ${number}"
  buildkite-agent meta-data set "random-number" "${number}"

  docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "echo ${number} > /usr/local/bundler/random-number"

  docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "echo ${number} > /srv/yarn/random-number"
else
  echo "--- Use cache"

  number=$(buildkite-agent meta-data get "random-number")
  echo "Using random number: ${number}"

  output=$(docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "cat /usr/local/bundler/random-number")

  if [[ ! "$output" =~ "$number" ]]; then
    echo "Failed to find random number!"
    exit 1
  fi

  output=$(docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "cat /srv/yarn/random-number")

  if [[ ! "$output" =~ "$number" ]]; then
    echo "Failed to find random number!"
    exit 1
  fi
fi
