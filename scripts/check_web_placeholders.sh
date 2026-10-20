#!/usr/bin/env bash
#
# Fails if a template placeholder is left in a web build, and names each file and placeholder.
#
# web/ keeps __KEY__ placeholders for template users (README, "Customizing for Your Project"), and flutter build web
# copies them into the build unchanged. Run this after scripts/fill_web_placeholders.sh and before publishing, so a
# placeholder without a value fails the deploy instead of reaching visitors. Two may stay: __KEYWORD__, which the
# instruction comments use for every placeholder, and __PROD_API_URL__, which appears only in an index.html comment
# and in the production AppConfig that a mock-only build such as the hosted demo never selects. canvaskit/ holds the
# Flutter engine, not app content, so it is not searched.
#
# Usage:
#   scripts/check_web_placeholders.sh BUILD_DIR

set -euo pipefail

# Byte-wise matching: [A-Z] means ASCII upper case, and no text file is skipped as binary for its encoding.
export LC_ALL=C

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 BUILD_DIR" >&2
  exit 2
fi
build_dir=$1
if [ ! -d "$build_dir" ]; then
  echo "error: build directory '$build_dir' does not exist" >&2
  exit 1
fi

# grep exits with 1 when it finds no placeholder at all, and with 2 when it cannot read the build.
status=0
found=$(grep -rIoE --exclude-dir=canvaskit '__[A-Z][A-Z0-9_]*__' "$build_dir") || status=$?
if [ "$status" -gt 1 ]; then
  echo "error: could not search $build_dir for placeholders" >&2
  exit "$status"
fi

# Each match is FILE:PLACEHOLDER.
left=$(printf '%s\n' "$found" | awk -F: '$NF != "" && $NF !~ /^__(KEYWORD|PROD_API_URL)__$/' | sort -u)
if [ -n "$left" ]; then
  {
    echo "error: template placeholders left in $build_dir:"
    printf '%s\n' "$left"
    echo "Give each one a value in web/ (README, \"Customizing for Your Project\")." \
      "The hosted demo takes its values from .github/pages/demo-values.env."
  } >&2
  exit 1
fi
echo "OK: no template placeholders left in $build_dir"
