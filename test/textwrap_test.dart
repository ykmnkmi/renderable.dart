// ignore_for_file: inference_failure_on_collection_literal

import 'package:renderable/src/textwrap.dart';
import 'package:test/test.dart';

void main() {
  group('TextWrapper', () {
    test('simple', () {
      final text = "Hello there, how are you this fine day?  I'm glad to hear it!";
      expect(TextWrapper(width: 12).wrap(text), equals(['Hello there,', 'how are you', 'this fine', "day?  I'm", 'glad to hear', 'it!']));
      expect(TextWrapper(width: 42).wrap(text), equals(['Hello there, how are you this fine day?', "I'm glad to hear it!"]));
      expect(TextWrapper(width: 80).wrap(text), equals([text]));
    });
  });
}
