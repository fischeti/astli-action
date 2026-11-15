#!/usr/bin/env bash
# Installs ccache unless it is on PATH, and points it at a directory in the
# runner's temp, which actions/cache then saves. astli hands ccache to
# Verilator as OBJCACHE wherever it is on PATH, so nothing else is needed.
# Says what keys the caches.
set -euo pipefail

if [ "$RUNNER_OS" = Windows ]; then
  echo "::warning::build-cache does nothing on Windows, where astli builds no testbench"
  echo "enabled=false" >>"$GITHUB_OUTPUT"
  exit 0
fi

if ! command -v ccache >/dev/null; then
  case "$RUNNER_OS" in
    Linux)
      sudo apt-get update -qq
      sudo apt-get install -y -qq ccache
      ;;
    macOS)
      brew install --quiet ccache
      ;;
  esac
fi

echo "CCACHE_DIR=$RUNNER_TEMP/ccache" >>"$GITHUB_ENV"
# Bounded, so that the cache saved after every run stays within what GitHub
# keeps for a repository.
if [ -z "${CCACHE_MAXSIZE:-}" ]; then
  echo "CCACHE_MAXSIZE=$BUILD_CACHE_SIZE" >>"$GITHUB_ENV"
fi
# A saved cache cannot be updated, so each run saves its own, and restores
# the newest of the same job, or else of the same runner. Legs of a matrix
# share a job's name, which BUILD_CACHE_KEY tells apart.
runner=$RUNNER_OS-$RUNNER_ARCH-
job=$runner$GITHUB_JOB-$BUILD_CACHE_KEY-
{
  echo "runner=$runner"
  echo "job=$job"
  echo "key=$job$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
  # A hosted runner names its image's OS release, which keeps its compiler's
  # ABI across the image's versions; a self-hosted one names none. The
  # version is left out: an image rolls out over days, so jobs of one run
  # land on different versions.
  echo "image=${ImageOS:-self-hosted}"
  echo "enabled=true"
} >>"$GITHUB_OUTPUT"
