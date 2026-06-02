#!/usr/bin/env bash
#
# Computes line coverage from an lcov file, EXCLUDING generated and bootstrap
# code, and fails if it is below a threshold.
#
# Why filter: `flutter test --coverage` instruments every executed lib/ file,
# including generated localization (lib/generated/**), codegen output
# (*.g.dart / *.freezed.dart), and app entry points (lib/main/main_*.dart).
# None of those carry hand-written, test-worthy logic, so counting them makes
# the headline number an unreliable quality signal (see issue #149).
#
# Usage:
#   scripts/check_coverage.sh [LCOV_FILE] [THRESHOLD]
# Defaults: coverage/lcov.info, 65
#
# Portable: pure bash + awk, no `lcov` binary required (avoids version-skew
# pain on CI runners). Reusable locally and in CI.

set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
THRESHOLD="${2:-65}"

if [ ! -f "$LCOV_FILE" ]; then
  echo "::warning::No coverage file at '$LCOV_FILE'; skipping coverage check"
  exit 0
fi

# Extended-regex of SF: paths excluded from the coverage metric.
EXCLUDE_RE='(^|/)lib/generated/|\.g\.dart$|\.freezed\.dart$|(^|/)lib/main/main_[^/]*\.dart$|\.config\.dart$'

read -r total hit excluded < <(awk -v ex="$EXCLUDE_RE" '
  /^SF:/ {
    path = substr($0, 4)
    skip = (path ~ ex) ? 1 : 0
    if (skip) excluded++
    next
  }
  skip { next }
  /^DA:/ { total++; if ($0 !~ /,0$/) hit++ }
  END   { printf "%d %d %d\n", total, hit, excluded }
' "$LCOV_FILE")

if [ "${total:-0}" -eq 0 ]; then
  echo "::warning::No instrumented lines after filtering; skipping coverage check"
  exit 0
fi

coverage=$(( hit * 100 / total ))
echo "Coverage (filtered): ${coverage}% — ${hit}/${total} lines (${excluded} generated/bootstrap files excluded)"

if [ "$coverage" -lt "$THRESHOLD" ]; then
  echo "::error::Coverage ${coverage}% is below ${THRESHOLD}% threshold"
  exit 1
fi
