#!/bin/bash

# Show a prompt for a command
function plugin_prompt() {
  if [[ -z "${HIDE_PROMPT:-}" ]] ; then
    echo -ne '\033[90m$\033[0m' >&2
    for arg in "${@}" ; do
      if [[ $arg =~ [[:space:]] ]] ; then
        echo -n " '$arg'" >&2
      else
        echo -n " $arg" >&2
      fi
    done
    echo >&2
  fi
}

# Shows the command being run, and runs it
function plugin_prompt_and_run() {
  plugin_prompt "$@"
  "$@"
}

# Shows the command about to be run, and exits if it fails
function plugin_prompt_and_must_run() {
  plugin_prompt_and_run "$@" || exit $?
}

# Shorthand for reading env config
function plugin_read_config() {
  local var="BUILDKITE_PLUGIN_DOCKER_CACHE_${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}

# Reads either a value or a list from plugin config
function plugin_read_list() {
  prefix_read_list "BUILDKITE_PLUGIN_DOCKER_CACHE_$1"
}

# Reads either a value or a list from the given env prefix
function prefix_read_list() {
  local prefix="$1"
  local parameter="${prefix}_0"

  if [[ -n "${!parameter:-}" ]]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [[ -n "${!parameter:-}" ]]; do
      echo "${!parameter}"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [[ -n "${!prefix:-}" ]]; then
    echo "${!prefix}"
  fi
}

# Reads either a value or a list from plugin config into a global result array
# Returns success if values were read
function plugin_read_list_into_result() {
  local prefix="$1"
  local parameter="${prefix}_0"
  result=()

  if [[ -n "${!parameter:-}" ]]; then
    local i=0
    local parameter="${prefix}_${i}"
    while [[ -n "${!parameter:-}" ]]; do
      result+=("${!parameter}")
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  elif [[ -n "${!prefix:-}" ]]; then
    result+=("${!prefix}")
  fi

  [[ ${#result[@]} -gt 0 ]] || return 1
}

# Returns the name of the docker compose project for this build
function docker_compose_project_name() {
  # No dashes or underscores because docker compose will remove them anyways
  echo "buildkite${BUILDKITE_JOB_ID//-}"
}

# Build an docker compose file that overrides the config for a
# list of volumes
function build_volume_override_file() {
  printf "services:\\n"
  printf "  docker-cache-buildkite-plugin:\\n"
  printf "    image: alpine:latest\\n"
  printf "    volumes:\\n"

  while test ${#} -gt 0 ; do
    printf "      - %s:/volumes/%s\\n" "$1" "$1"
    shift
  done
}

function cache_hit() {
  echo "--- 🔥 Cache hit: $1"
}

function cache_restore_skip() {
  echo "--- 🚨 Cache restore is skipped because $1 does not exist"
}

function cache_save_skip() {
  echo "--- Skipping cache save; cache already exists: $1"
}

function cache_save() {
  echo "--- :fire: Saving cache: $1"
}

function expand_key() {
  CACHE_KEY="$1"
  HASHER_BIN="sha1sum"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    HASHER_BIN="shasum"
  fi

  while [[ "$CACHE_KEY" =~ (.*)\{\{\ *(.*)\ *\}\}(.*) ]]; do
    TEMPLATE_VALUE="${BASH_REMATCH[2]}"
    EXPANDED_VALUE=""
    if [[ $TEMPLATE_VALUE == "checksum "* ]]; then
      TARGET="$(echo -e "${TEMPLATE_VALUE/"checksum"/""}" | tr -d \' | tr -d \" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      EXPANDED_VALUE=$(find "$TARGET" -type f -exec $HASHER_BIN {} \; | sort -k 2 | $HASHER_BIN | awk '{print $1}')
    elif [[ $TEMPLATE_VALUE == "arch"* ]]; then
      EXPANDED_VALUE="$(uname -s)-$(uname -m)"
      EXPANDED_VALUE="${EXPANDED_VALUE,,}"
    else
      echo >&2 "Invalid template expression: $TEMPLATE_VALUE"
      return 1
    fi
    CACHE_KEY="${BASH_REMATCH[1]}${EXPANDED_VALUE}${BASH_REMATCH[3]}"
  done

  CACHE_KEY=${CACHE_KEY//\//-}
  echo "$CACHE_KEY"
}
