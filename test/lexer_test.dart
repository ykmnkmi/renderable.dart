import 'package:renderable/jinja.dart';
import 'package:renderable/src/reader.dart';
import 'package:renderable/src/lexer.dart';
import 'package:test/test.dart';

void main() {
  group('TokenReader', () {
    const testTokens = <Token>[Token(1, 'block_begin', ''), Token(2, 'block_end', '')];
    test('simple', () {
      final reader = TokenReader(testTokens);
      expect(reader.current.test('block_begin'), isTrue);
      reader.next();
      expect(reader.current.test('block_end'), isTrue);
    });

    test('simple', () {
      final reader = TokenReader(testTokens);
      final tokenTypes = <String>[for (final token in reader.values) token.type];
      expect(tokenTypes, equals(['block_begin', 'block_end']));
    });
  });

  group('Lexer', () {
    final environment = Environment();

    test('raw', () {
      final template = environment.fromString('{% raw %}foo{% endraw %}|'
          '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}');
      expect(template.render(), equals('foo|{{ bar }}|{% baz %}'));
    });

    test('raw2', () {
      final template = environment.fromString('1  {%- raw -%}   2   {%- endraw -%}   3');
      expect(template.render(), equals('123'));
    });

    test('raw3', () {
      final env = Environment(lStripBlocks: true, trimBlocks: true);
      final template = env.fromString('bar\n{% raw %}\n  {{baz}}2 spaces\n{% endraw %}\nfoo');
      expect(template.render({'baz': 'test'}), equals('bar\n\n  {{baz}}2 spaces\nfoo'));
    });

    test('raw4', () {
      final env = Environment(lStripBlocks: true);
      final template = env.fromString('bar\n{%- raw -%}\n\n  \n  2 spaces\n space{%- endraw -%}\nfoo');
      expect(template.render(), equals('bar2 spaces\n spacefoo'));
    });
  });
}
