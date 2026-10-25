#!/usr/bin/env bash
# Installs astli $INPUT_VERSION from its GitHub release into the runner's tool
# cache and puts it on PATH. Runs under bash on every runner, Git Bash on
# Windows.
set -euo pipefail

version=${INPUT_VERSION#v}
case "$RUNNER_OS-$RUNNER_ARCH" in
  Linux-X64) target=x86_64-unknown-linux-gnu ;;
  Linux-ARM64) target=aarch64-unknown-linux-gnu ;;
  macOS-X64) target=x86_64-apple-darwin ;;
  macOS-ARM64) target=aarch64-apple-darwin ;;
  Windows-X64) target=x86_64-pc-windows-msvc ;;
  *)
    echo "::error::astli has no prebuilt binary for $RUNNER_OS on $RUNNER_ARCH"
    exit 1
    ;;
esac

if [ "$RUNNER_OS" = Windows ]; then
  archive=astli-cli-$target.zip
  exe=astli.exe
  tool_cache=$(cygpath -u "$RUNNER_TOOL_CACHE")
  temp=$(cygpath -u "$RUNNER_TEMP")
else
  archive=astli-cli-$target.tar.xz
  exe=astli
  tool_cache=$RUNNER_TOOL_CACHE
  temp=$RUNNER_TEMP
fi

# The layout and the .complete marker are those @actions/tool-cache uses, so a
# self-hosted runner keeps the binary across jobs.
dir=$tool_cache/astli/$version/$RUNNER_ARCH
if [ -f "$dir.complete" ]; then
  echo "astli $version is in the tool cache"
else
  url=https://github.com/fischeti/astli/releases/download/v$version/$archive
  work=$(mktemp -d "$temp/astli.XXXXXX")
  curl -fsSL --retry 3 -o "$work/$archive" "$url"
  curl -fsSL --retry 3 -o "$work/$archive.sha256" "$url.sha256"

  expected=$(cut -d' ' -f1 "$work/$archive.sha256")
  if command -v sha256sum >/dev/null; then
    actual=$(sha256sum "$work/$archive" | cut -d' ' -f1)
  else
    actual=$(shasum -a 256 "$work/$archive" | cut -d' ' -f1)
  fi
  if [ "$actual" != "$expected" ]; then
    echo "::error::$archive has checksum $actual, expected $expected"
    exit 1
  fi

  mkdir "$work/x"
  if [ "$RUNNER_OS" = Windows ]; then
    unzip -q "$work/$archive" -d "$work/x"
  else
    tar -xJf "$work/$archive" -C "$work/x"
  fi
  # The tarballs hold a directory named after the archive, the zip does not.
  bin=$(find "$work/x" -name "$exe" -type f | head -n 1)
  rm -rf "$dir"
  mkdir -p "$dir"
  mv "$bin" "$dir/"
  touch "$dir.complete"
  rm -rf "$work"
fi

if [ "$RUNNER_OS" = Windows ]; then
  cygpath -w "$dir" >>"$GITHUB_PATH"
else
  echo "$dir" >>"$GITHUB_PATH"
fi
echo "version=$version" >>"$GITHUB_OUTPUT"
