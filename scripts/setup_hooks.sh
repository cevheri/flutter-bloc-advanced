#!/usr/bin/env bash
set -euo pipefail

# Setup Git hooks for flutter_bloc_advance
# Usage: bash scripts/setup_hooks.sh

HOOKS_DIR="$(git rev-parse --show-toplevel)/.git/hooks"

echo "Installing git hooks..."

# pre-commit: format check + static analysis
cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-commit checks..."

# Check formatting
echo "  Checking format..."
if ! fvm dart format . --line-length=120 --set-exit-if-changed > /dev/null 2>&1; then
  echo "  ✗ Formatting issues found. Run: fvm dart format . --line-length=120"
  exit 1
fi
echo "  ✓ Format OK"

# Static analysis
echo "  Running analysis..."
if ! fvm dart analyze --no-fatal-infos 2>/dev/null; then
  echo "  ✗ Analysis errors found. Run: fvm dart analyze"
  exit 1
fi
echo "  ✓ Analysis OK"

echo "Pre-commit checks passed."
HOOK
chmod +x "$HOOKS_DIR/pre-commit"

# pre-push: run tests
cat > "$HOOKS_DIR/pre-push" << 'HOOK'
#!/usr/bin/env bash
set -euo pipefail

echo "Running pre-push checks..."

echo "  Running tests..."
if ! fvm flutter test --no-pub 2>/dev/null; then
  echo "  ✗ Tests failed. Fix failing tests before pushing."
  exit 1
fi
echo "  ✓ Tests passed"

echo "Pre-push checks passed."
HOOK
chmod +x "$HOOKS_DIR/pre-push"

echo "Git hooks installed:"
echo "  pre-commit: format check + static analysis"
echo "  pre-push:   flutter test"
echo ""
echo "To skip hooks temporarily: git commit --no-verify"
