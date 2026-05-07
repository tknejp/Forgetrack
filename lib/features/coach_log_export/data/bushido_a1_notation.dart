/// Converts a 0-indexed column offset to A1-notation column letters.
/// 0 → 'A', 1 → 'B', ..., 25 → 'Z', 26 → 'AA', 27 → 'AB', ...
String columnLetter(int offset) {
  assert(offset >= 0, 'column offset must be non-negative');
  var n = offset;
  final buf = StringBuffer();
  while (true) {
    buf.write(String.fromCharCode('A'.codeUnitAt(0) + (n % 26)));
    n = n ~/ 26 - 1;
    if (n < 0) break;
  }
  return buf.toString().split('').reversed.join();
}
