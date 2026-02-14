
void main() {
  print('🧪 TESTING TIMESTAMP CALCULATION');
  
  final now = DateTime.now();
  final epoch = DateTime.utc(1989, 12, 31, 0, 0, 0);
  
  print('Now: $now');
  print('Epoch: $epoch');
  
  final msNow = now.millisecondsSinceEpoch;
  final msEpoch = epoch.millisecondsSinceEpoch;
  
  print('msNow: $msNow');
  print('msEpoch: $msEpoch');
  
  final startFit = (msNow - msEpoch) ~/ 1000;
  print('Calculated startFit (seconds): $startFit');
  
  // 4296106816000 ?
  // If startFit was treated as ms?
  // 1.1 billion ms = 1 million seconds (11 days). Wrong.
  
  // What equals 4296106816000?
  // It is approx 2^32 * 1000?
  // 2^32 = 4294967296.
  // 4296106816000 / 1000 = 4296106816.
  // This is suspiciously close to 2^32.
  
  // If I passed `startFit` (1.1 billion)
  // And reading back gets 4.2 trillion...
  
  // Wait.
  // 4294967296 + startFit?
  // 4.29e9 + 1.14e9 = 5.4e9.
  
  // What if I passed NEGATIVE value?
  // -1 in uint32 is 4294967295.
  // If `startFit` was around -1...
  // But it is 1.1 billion.
  
  print('CHECKING HEX VALUES:');
  print('1.14e9 in Hex: 0x${startFit.toRadixString(16)}');
}
