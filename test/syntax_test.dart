import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:test/test.dart';

void main() {
  group('Syntax', () {
    test('call', () {
      final environment = Environment();
      environment.globals['foo'] = (dynamic a, dynamic b, {dynamic c, dynamic e, dynamic g}) => a + b + c + e + g;
      final template = environment.fromString('{{ foo("a", c="d", e="f", *["b"], **{"g": "h"}) }}');
      expect(template.render(), equals('abdfh'));
    });

    test('slicing', () {
      final environment = Environment();
      final template = environment.fromString('{{ [1, 2, 3][:] }}|{{ [1, 2, 3][::-1] }}');
      expect(template.render(), equals('[1, 2, 3]|[3, 2, 1]'));
    });

    test('attr', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo.bar }}|{{ foo["bar"] }}');
      expect(render(template, foo: {'bar': 42}), equals('42|42'));
    });

    test('subscript', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo[0] }}|{{ foo[-1] }}');
      expect(render(template, foo: [0, 1, 2]), equals('0|2'));
    });

    test('tuple', () {
      final environment = Environment();
      final template = environment.fromString('{{ () }}|{{ (1,) }}|{{ (1, 2) }}');
      expect(template.render(), equals('[]|[1]|[1, 2]')); // tuple is list
    });

    test('math', () {
      final environment = Environment();
      final template = environment.fromString('{{ (1 + 1 * 2) - 3 / 2 }}|{{ 2**3 }}');
      expect(template.render(), equals('1.5|8'));
    });

    test('div', () {
      final environment = Environment();
      final template = environment.fromString('{{ 3 // 2 }}|{{ 3 / 2 }}|{{ 3 % 2 }}');
      expect(template.render(), equals('1|1.5|1'));
    });

    test('unary', () {
      final environment = Environment();
      final template = environment.fromString('{{ +3 }}|{{ -3 }}');
      expect(template.render(), equals('3|-3'));
    });

    test('concat', () {
      final environment = Environment();
      final template = environment.fromString('{{ [1, 2] ~ "foo" }}');
      expect(template.render(), equals('[1, 2]foo'));
    });

    test('compare', () {
      final comparsions = {'>': [1, 0], '>=': [1,  1], '<': [2, 3], '<=': [3,  4], '==': [4,  4], '!=': [4,  5]};
      final environment = Environment();

      comparsions.forEach((operation, pair) {
        final template = environment.fromString('{{ ${pair.first} $operation ${pair.last} }}');
        expect(template.render(), equals('true'));
      });
    });

    test('compare parens', () {
      final environment = Environment();
      // num * bool not supported
      // '{{ i * (j < 5) }}'
      final template = environment.fromString('{{ i == (j < 5) }}');
      expect(render(template, i: 2, j: 3), equals('false'));
    });

    // TODO: https://github.com/pallets/jinja/blob/81911fdb3065f1156d84ca52ee3a257c229ebc59/tests/test_lexnparse.py#L376
  });
}
