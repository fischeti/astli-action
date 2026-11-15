#!/usr/bin/env bash
# Installs astli $INPUT_VERSION with the installer its release ships, which
# picks the archive for the runner, checks its checksum, and falls back to
# a static build where glibc is too old. Runs under bash on every runner,
# Git Bash on Windows.
set -euo pipefail

version=${INPUT_VERSION#v}
if [ "$RUNNER_OS" = Windows ]; then
  temp=$(cygpath -u "$RUNNER_TEMP")
else
  temp=$RUNNER_TEMP
fi
dir=$temp/astli/$version
installer=$temp/astli-installer.sh

url=https://github.com/fischeti/astli/releases/download/v$version/astli-cli-installer.sh
curl -fsSL --retry 3 -o "$installer" "$url"
# Unmanaged, it installs into $dir alone, and leaves the PATH and the shell's
# profiles as they are.
ASTLI_CLI_UNMANAGED_INSTALL=$dir sh "$installer" --quiet
rm -f "$installer"

if [ "$RUNNER_OS" = Windows ]; then
  cygpath -w "$dir" >>"$GITHUB_PATH"
else
  echo "$dir" >>"$GITHUB_PATH"
fi
echo "version=$version" >>"$GITHUB_OUTPUT"
