import 'package:test/test.dart';
import 'package:textwrap/textwrap.dart';

void main() {
  group('TextWrapper', () {
    void check(List<String> result, List<String> expekt) {
      expect(result, equals(expekt));
    }

    test('simple', () {
      final text = "Hello there, how are you this fine day?  I'm glad to hear it!";
      check(wrap(text, width: 12), ['Hello there,', 'how are you', 'this fine', "day?  I'm", 'glad to hear', 'it!']);
      check(wrap(text, width: 42), ['Hello there, how are you this fine day?', "I'm glad to hear it!"]);
      check(wrap(text, width: 80), [text]);
    });

    test('empty string', () {
      final text = '';
      check(wrap(text, width: 6), []);
      check(wrap(text, width: 6, dropWhitespace: false), []);
    });
  });
}
