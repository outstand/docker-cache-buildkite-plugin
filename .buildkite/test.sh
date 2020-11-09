#!/bin/bash

set -euo pipefail

compose_params=(-f docker-compose.yml)
if [[ -n "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE:-}" ]] ; then
  compose_params+=(-f "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_OVERRIDE_FILE}")
fi

compose_params+=(-p "${BUILDKITE_PLUGIN_DOCKER_COMPOSE_PROJECT_NAME}")

echo "--- :docker: Pulling image"
docker-compose "${compose_params[@]}" pull tests

echo "--- :bash: Running tests"
docker-compose "${compose_params[@]}" run --rm tests
