/// Tiny semver helper. Compares major.minor.patch versions as integer
/// triples; missing components are treated as zero. Pre-release and
/// build metadata are intentionally not supported — the app config
/// only ships numeric versions and adding the full spec would be
/// scope creep.
///
/// Pure: testable as a domain unit, no dependency on logging or BLoC.
class Semver {
  Semver._();

  /// One to three dot-separated runs of digits, nothing else.
  static final _version = RegExp(r'^\d+(\.\d+){0,2}$');

  /// Returns true when [current] is strictly below [minimum].
  ///
  /// Throws a [FormatException] naming the value when either version is
  /// malformed; the caller decides what an unknown version means and logs it.
  static bool isBelow(String current, String minimum) {
    final c = _parts(current);
    final m = _parts(minimum);
    for (var i = 0; i < 3; i++) {
      final a = i < c.length ? c[i] : 0;
      final b = i < m.length ? m[i] : 0;
      if (a < b) return true;
      if (a > b) return false;
    }
    return false;
  }

  static List<int> _parts(String version) {
    if (!_version.hasMatch(version)) {
      throw FormatException('Malformed version "$version", expected major[.minor[.patch]]');
    }
    return version.split('.').map(int.parse).toList();
  }
}
