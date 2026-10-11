import 'dart:math';

final class IdGenerator {
  static final Random _random = Random();
  static const String _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  IdGenerator._();

  static String next() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      10,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();

    return '${timestamp}_$randomPart';
  }
}
