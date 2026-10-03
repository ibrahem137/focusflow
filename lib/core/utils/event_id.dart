import 'dart:math';

String newEventId() {
  final random = Random.secure();
  return '${DateTime.now().microsecondsSinceEpoch}-'
      '${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
