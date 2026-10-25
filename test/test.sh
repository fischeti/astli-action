#!/usr/bin/env bash
# Checks the astli the action installed, $VERSION, on the package here, whose
# rtl/top.sv is formatted and leaves a signal unused on purpose.
set -euo pipefail

actual=$(astli --version)
if [ "$actual" != "astli $VERSION" ]; then
  echo "::error::expected astli $VERSION, found $actual"
  exit 1
fi

# astli before 0.4.0 has no packages: it is given the file.
IFS=. read -r major minor _ <<<"$VERSION"
new=false
files=rtl/top.sv
if [ "$major" -gt 0 ] || [ "$minor" -ge 4 ]; then
  new=true
  files=
fi

# shellcheck disable=SC2086 # $files is no file or one without spaces.
astli fmt --check $files

tmp=$(mktemp -d)
unformatted=$tmp/unformatted.sv
printf 'module m;\nlogic a;endmodule\n' >"$unformatted"
if astli fmt --check "$unformatted"; then
  echo "::error::fmt --check passed an unformatted file"
  exit 1
fi

# shellcheck disable=SC2086
astli lint $files 2>"$tmp/lint.log" || {
  cat "$tmp/lint.log"
  echo "::error::lint failed on warnings alone"
  exit 1
}
cat "$tmp/lint.log"
grep -q 'unused-signal' "$tmp/lint.log"
if [ "$new" = true ] && ! grep -q '^::warning ' "$tmp/lint.log"; then
  echo "::error::lint wrote no ::warning workflow command"
  exit 1
fi
