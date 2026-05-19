/// Tiny semver helper. Compares major.minor.patch versions as integer
/// triples; missing components are treated as zero. Pre-release and
/// build metadata are intentionally not supported — the app config
/// only ships numeric versions and adding the full spec would be
/// scope creep.
///
/// Pure: testable as a domain unit, no dependency on logging or BLoC.
class Semver {
  Semver._();

  /// Returns true when [current] is strictly below [minimum].
  /// Returns false on any parse error (caller decides what "unknown
  /// version" means; for our lifecycle gate that means "don't force an
  /// update").
  static bool isBelow(String current, String minimum) {
    try {
      final c = _parts(current);
      final m = _parts(minimum);
      for (var i = 0; i < 3; i++) {
        final a = i < c.length ? c[i] : 0;
        final b = i < m.length ? m[i] : 0;
        if (a < b) return true;
        if (a > b) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parts(String version) => version.split('.').map(int.parse).toList();
}
