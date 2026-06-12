class VersionUtils {
  VersionUtils._();

  /// Compares two semantic version strings (e.g., '1.0.0' and '1.0.1').
  /// Returns [true] if [current] is older than [target].
  static bool isVersionOlder(String current, String target) {
    if (current.trim().isEmpty || target.trim().isEmpty) return false;
    try {
      // Strip builds tags/hashes if present (e.g. '1.0.0+1' -> '1.0.0')
      final cleanCurrent = current.split('+').first;
      final cleanTarget = target.split('+').first;

      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final targetParts = cleanTarget.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final currentVal = i < currentParts.length ? currentParts[i] : 0;
        final targetVal = i < targetParts.length ? targetParts[i] : 0;

        if (currentVal < targetVal) return true;
        if (currentVal > targetVal) return false;
      }
    } catch (_) {}
    return false;
  }
}
