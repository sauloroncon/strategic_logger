import 'package:test/test.dart';

void main() {
  group('Basic Dart Tests', () {
    test('should pass basic test', () {
      expect(1 + 1, equals(2));
    });

    test('should handle string operations', () {
      final message = 'Hello World';
      expect(message.length, equals(11));
      expect(message.toUpperCase(), equals('HELLO WORLD'));
    });

    test('should handle list operations', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.length, equals(5));
      expect(list.first, equals(1));
      expect(list.last, equals(5));
    });

    test('should handle map operations', () {
      final map = {'key1': 'value1', 'key2': 'value2'};
      expect(map.length, equals(2));
      expect(map['key1'], equals('value1'));
      expect(map.containsKey('key2'), isTrue);
    });

    test('should handle async operations', () async {
      final future = Future.delayed(
        Duration(milliseconds: 10),
        () => 'async result',
      );
      final result = await future;
      expect(result, equals('async result'));
    });
  });
}
