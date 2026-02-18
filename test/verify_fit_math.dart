void main() {
  final now = DateTime.now();
  final fitEpoch = DateTime.utc(1989, 12, 31, 0, 0, 0).millisecondsSinceEpoch;
  final unixEpoch = DateTime.utc(1970, 1, 1, 0, 0, 0).millisecondsSinceEpoch;

  int toFitTime(DateTime dt) => (dt.millisecondsSinceEpoch - fitEpoch) ~/ 1000;

  print('Now: $now');
  print('Now (Unix ms): ${now.millisecondsSinceEpoch}');
  print('Fit Epoch (ms): $fitEpoch');
  print('Calculated FIT Time: ${toFitTime(now)}');

  // Check 2043 scenario
  const fit2043 = 1735689600; // Approx Unix for 2025? No.
  // Unix Now ~ 1.73 Billion.
  // 1.73B seconds since 1989?
  // 1989 + 1.73B seconds = 1989 + 54 years = 2043.
  // So if I passed Unix Time as FIT Time, it IS 2043.
  
  // Valid FIT Time for 2025:
  // 2025 - 1989 = 36 years.
  // 36 * 31.5M sec = ~1.1 Billion.
  
  final calc = toFitTime(now);
  print('Is Valid Logic? ${calc > 1000000000 && calc < 1200000000}');
}
