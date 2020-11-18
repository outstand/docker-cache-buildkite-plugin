#!/bin/bash

set -euo pipefail

compose_params=()
IFS=' ' read -r -a config_files <<< "${DOCKER_COMPOSE_CONFIG_FILES:-}"

for file in "${config_files[@]}"; do
  [[ -n "${file:-}" ]] && compose_params+=(-f "$file")
done

if [[ -n "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE:-}" ]] ; then
  compose_params+=(-f "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE}")
fi

compose_params+=(-p "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_PROJECT_NAME}")

if [[ "${1:-}" = "populate" ]]; then
  echo "+++ Populate cache"

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
  echo "+++ Use cache"

  number=$(buildkite-agent meta-data get "random-number")
  echo "Using random number: ${number}"

  output=$(docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "cat /usr/local/bundler/random-number")

  if [[ "$output" =~ "$number" ]]; then
    echo "Found number:"
    echo "${output}"
  else
    echo "Failed to find random number!"
    exit 1
  fi

  output=$(docker-compose \
    "${compose_params[@]}" \
    run --rm \
    rails \
    sh -c "cat /srv/yarn/random-number")

  if [[ "$output" =~ "$number" ]]; then
    echo "Found number:"
    echo "${output}"
  else
    echo "Failed to find random number!"
    exit 1
  fi
fi
