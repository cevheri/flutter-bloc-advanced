#!/usr/bin/env bash
#
# Fills the template placeholders of a web build with the values of one deployment.
#
# web/ keeps __KEY__ placeholders for template users (README, "Customizing for Your Project"), and flutter build web
# copies them into the build unchanged. This script replaces each __KEY__ in index.html, manifest.json, sitemap.xml
# and humans.txt under BUILD_DIR with the value of the KEY=value line in VALUES_FILE, and strips the instruction for
# template users from the humans.txt header. It never changes web/ itself.
#
# A value is inserted as it is, so a value that would need escaping in HTML, JSON or XML (one of " < > & \ | or a
# control character) fails the script instead of being escaped. Empty lines and lines starting with # are skipped.
# A placeholder without a value is left in place; scripts/check_web_placeholders.sh fails on it afterwards.
#
# Usage:
#   scripts/fill_web_placeholders.sh VALUES_FILE BUILD_DIR
# The GitHub Pages job runs it for the hosted demo as:
#   scripts/fill_web_placeholders.sh .github/pages/demo-values.env build/web

set -euo pipefail

# Byte-wise matching, so [A-Z] means ASCII upper case whatever the caller's locale.
export LC_ALL=C

fail() {
  echo "error: $*" >&2
  exit 1
}

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 VALUES_FILE BUILD_DIR" >&2
  exit 2
fi
values_file=$1
build_dir=$2
files=(index.html manifest.json sitemap.xml humans.txt)

[ -f "$values_file" ] || fail "values file '$values_file' does not exist"
for file in "${files[@]}"; do
  [ -f "$build_dir/$file" ] || fail "'$build_dir/$file' does not exist; build the web app first"
done

# One sed expression per value. KEY matches [A-Z][A-Z0-9_]* and the value holds no & \ or |, so neither side of
# s|__KEY__|value|g needs escaping.
substitutions=()
keys=' '
count=0
line_number=0
while IFS= read -r line || [ -n "$line" ]; do
  line_number=$((line_number + 1))
  case $line in
    '' | '#'*) continue ;;
  esac
  [[ $line =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]] ||
    fail "$values_file:$line_number: expected KEY=value with a KEY of A-Z, 0-9 and _"
  key=${BASH_REMATCH[1]}
  value=${BASH_REMATCH[2]}
  case $keys in
    *" $key "*) fail "$values_file:$line_number: $key is set twice" ;;
  esac
  [ -n "$value" ] || fail "$values_file:$line_number: $key has an empty value"
  case $value in
    *\"* | *\<* | *\>* | *\&* | *\\* | *\|* | *[[:cntrl:]]*)
      fail "$values_file:$line_number: the value of $key contains one of \" < > & \\ | or a control character," \
        "which would need escaping in HTML, JSON or XML"
      ;;
  esac
  keys="$keys$key "
  count=$((count + 1))
  substitutions+=(-e "s|__${key}__|${value}|g")
done < "$values_file"
[ "$count" -gt 0 ] || fail "$values_file sets no KEY=value"

# Runs before the substitutions, so it matches the header as web/humans.txt writes it.
humans_instruction='s|^/\* TEAM - Replace __KEYWORD__ placeholders with your values \*/$|/* TEAM */|'

tmp=$(mktemp "${TMPDIR:-/tmp}/fill_web_placeholders.XXXXXX")
trap 'rm -f "$tmp"' EXIT
for file in "${files[@]}"; do
  if [ "$file" = humans.txt ]; then
    sed -e "$humans_instruction" "${substitutions[@]}" "$build_dir/$file" > "$tmp"
  else
    sed "${substitutions[@]}" "$build_dir/$file" > "$tmp"
  fi
  # Writing over the file, instead of moving the temporary file onto it, keeps its permissions.
  cat "$tmp" > "$build_dir/$file"
done

if grep -q '__KEYWORD__' "$build_dir/humans.txt"; then
  fail "$build_dir/humans.txt still has the instruction for template users; update humans_instruction in $0" \
    "to match web/humans.txt"
fi

echo "Filled${keys% } from $values_file into ${files[*]} under $build_dir"
