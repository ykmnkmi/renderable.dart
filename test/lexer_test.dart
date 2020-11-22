import 'package:test/test.dart';

import 'package:renderable/src/reader.dart';
import 'package:renderable/src/lexer.dart';

void main() {
  group('TokenReader', () {
    const testTokens = <Token>[Token(1, 'block_begin', ''), Token(2, 'block_end', '')];
    test('simple', () {
      var reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      expect(reader.isClosed, isFalse);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
      expect(reader.isClosed, isFalse);
      reader.next();
      expect(reader.isClosed, isTrue);
    });

    test('simple', () {
      var reader = TokenReader(testTokens);
      var tokenTypes = <String>[for (var token in reader.values) token.type];
      expect(tokenTypes, equals(['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    test('simple', () {});
  });
}
