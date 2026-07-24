import 'dart:math';

abstract class UuidGenerator {
  static final Random _random = Random.secure();

  static String generateV4() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));

    // Set version to 4 (0100)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to 10xx
    values[8] = (values[8] & 0x3f) | 0x80;

    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  static bool isValidUuid(String input) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(input);
  }
}
