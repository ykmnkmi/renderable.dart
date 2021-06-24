import 'package:renderable/jinja.dart';
import 'package:renderable/src/nodes.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

class Foo {
  Object? operator [](Object? key) {
    return key;
  }
}

void main() {
  group('Syntax', () {
    late final environment = Environment();

    test('call', () {
      var globals = {'foo': (dynamic a, dynamic b, {dynamic c, dynamic e, dynamic g}) => a + b + c + e + g};
      var environment = Environment(globals: globals);
      expect(environment.fromString('{{ foo("a", c="d", e="f", *["b"], **{"g": "h"}) }}').render(), equals('abdfh'));
    });

    test('slicing', () {
      expect(
          environment.fromString('{{ [1, 2, 3][:] }}|{{ [1, 2, 3][::-1] }}').render(), equals('[1, 2, 3]|[3, 2, 1]'));
    });

    test('attr', () {
      expect(
          environment.fromString('{{ foo.bar }}|{{ foo["bar"] }}').render({
            'foo': {'bar': 42}
          }),
          equals('42|42'));
    });

    test('subscript', () {
      expect(
          environment.fromString('{{ foo[0] }}|{{ foo[-1] }}').render({
            'foo': [0, 1, 2]
          }),
          equals('0|2'));
    });

    test('tuple', () {
      // tuple is list
      expect(environment.fromString('{{ () }}|{{ (1,) }}|{{ (1, 2) }}').render(), equals('[]|[1]|[1, 2]'));
    });

    test('math', () {
      expect(environment.fromString('{{ (1 + 1 * 2) - 3 / 2 }}|{{ 2**3 }}').render(), equals('1.5|8'));
    });

    test('div', () {
      expect(environment.fromString('{{ 3 // 2 }}|{{ 3 / 2 }}|{{ 3 % 2 }}').render(), equals('1|1.5|1'));
    });

    test('unary', () {
      expect(environment.fromString('{{ +3 }}|{{ -3 }}').render(), equals('3|-3'));
    });

    test('concat', () {
      expect(environment.fromString('{{ [1, 2] ~ "foo" }}').render(), equals('[1, 2]foo'));
    });

    test('compare', () {
      expect(environment.fromString('{{ 1 > 0 }}').render(), equals('true'));
      expect(environment.fromString('{{ 1 >= 1 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 < 3 }}').render(), equals('true'));
      expect(environment.fromString('{{ 3 <= 4 }}').render(), equals('true'));
      expect(environment.fromString('{{ 4 == 4 }}').render(), equals('true'));
      expect(environment.fromString('{{ 4 != 5 }}').render(), equals('true'));
    });

    test('compare parens', () {
      // num * bool not supported
      // '{{ i * (j < 5) }}'
      expect(environment.fromString('{{ i == (j < 5) }}').render({'i': 2, 'j': 3}), equals('false'));
    });

    test('compare compound', () {
      var data = {'a': 4, 'b': 2, 'c': 3};
      expect(environment.fromString('{{ 4 < 2 < 3 }}').render(data), equals('false'));
      expect(environment.fromString('{{ a < b < c }}').render(data), equals('false'));
      expect(environment.fromString('{{ 4 > 2 > 3 }}').render(data), equals('false'));
      expect(environment.fromString('{{ a > b > c }}').render(data), equals('false'));
      expect(environment.fromString('{{ 4 > 2 < 3 }}').render(data), equals('true'));
      expect(environment.fromString('{{ a > b < c }}').render(data), equals('true'));
    });

    test('inop', () {
      expect(environment.fromString('{{ 1 in [1, 2, 3] }}|{{ 1 not in [1, 2, 3] }}').render(), equals('true|false'));
    });

    test('collection literal', () {
      var matches = {'[]': '[]', '{}': '{}', '()': '[]'}; // tuple is list

      matches.forEach((source, expekt) {
        expect(environment.fromString('{{ $source }}').render(), equals(expekt));
      });
    });

    test('numeric literal', () {
      var matches = {
        '1': '1',
        '123': '123',
        '12_34_56': '123456',
        '1.2': '1.2',
        '34.56': '34.56',
        '3_4.5_6': '34.56',
        '1e0': '1.0',
        '10e1': '100.0',
        '2.5e100': '2.5e+100',
        '2.5e+100': '2.5e+100',
        '25.6e-10': /* difference: '2.56e-09' */ '2.56e-9',
        '1_2.3_4e5_6': '1.234e+57',
      };

      matches.forEach((source, expekt) {
        expect(environment.fromString('{{ $source }}').render(), equals(expekt));
      });
    });

    test('bool', () {
      expect(environment.fromString('{{ true and false }}|{{ false or true }}|{{ not false }}').render(),
          equals('false|true|true'));
    });

    test('grouping', () {
      expect(
          environment.fromString('{{ (true and false) or (false and true) and not false }}').render(), equals('false'));
    });

    test('django attr', () {
      expect(environment.fromString('{{ [1, 2, 3].0 }}|{{ [[1]].0.0 }}').render(), equals('1|1'));
    });

    test('conditional expression', () {
      expect(environment.fromString('{{ 0 if true else 1 }}').render(), equals('0'));
    });

    test('short conditional expression', () {
      expect(environment.fromString('<{{ 1 if false }}>').render(), equals('<>'));
    });

    test('filter priority', () {
      expect(environment.fromString('{{ "foo" | upper + "bar" | upper }}').render(), equals('FOOBAR'));
    });

    test('function calls', () {
      var matches = {
        '*foo, bar': true,
        '*foo, *bar': true,
        '**foo, *bar': true,
        '**foo, bar': true,
        '**foo, **bar': true,
        '**foo, bar=42': true,
        'foo, bar': false,
        'foo, bar=42': false,
        'foo, bar=23, *args': false,
        'foo, *args, bar=23': false,
        'a, b=c, *d, **e': false,
        '*foo, bar=42': false,
        '*foo, **bar': false,
        '*foo, bar=42, **baz': false,
        'foo, *args, bar=23, **baz': false,
      };

      matches.forEach((sig, shouldFail) {
        if (shouldFail) {
          expect(() => environment.fromString('{{ foo($sig) }}'), equals(throwsA(isA<TemplateSyntaxError>())));
        } else {
          expect(environment.fromString('{{ foo($sig) }}'), isA<Template>());
        }
      });
    });

    test('tuple expr', () {
      var sources = <String>[
        '{{ () }}',
        '{{ (1, 2) }}',
        '{{ (1, 2,) }}',
        '{{ 1, }}',
        '{{ 1, 2 }}',
        '{% for foo, bar in seq %}...{% endfor %}',
        '{% for x in foo, bar %}...{% endfor %}',
        '{% for x in foo, %}...{% endfor %}',
      ];

      for (var source in sources) {
        expect(environment.fromString(source), isA<Template>());
      }
    });

    test('triling comma', () {
      // tuple is list
      expect(
          environment.fromString('{{ (1, 2,) }}|{{ [1, 2,] }}|{{ {1: 2,} }}').render(), equals('[1, 2]|[1, 2]|{1: 2}'));
    });

    test('block end name', () {
      expect(environment.fromString('{% block foo %}...{% endblock foo %}'), isA<Template>());
      expect(
          () => environment.fromString('{% block x %}{% endblock y %}').render(), throwsA(isA<TemplateSyntaxError>()));
    });

    test('string concatenation', () {
      expect(environment.fromString('{{ "foo" "bar" "baz" }}').render(), equals('foobarbaz'));
    });

    test('notin', () {
      expect(environment.fromString('{{ not 42 in bar }}').render({'bar': range(100)}), equals('false'));
    });

    test('operator precedence', () {
      expect(environment.fromString('{{ 2 * 3 + 4 % 2 + 1 - 2 }}').render(), equals('5'));
    });

    test('implicit subscribed tuple', () {
      // tuple is list
      expect(environment.fromString('{{ foo[1, 2] }}').render({'foo': Foo()}), equals('[1, 2]'));
    });

    test('raw2', () {
      // tuple is list
      expect(environment.fromString('{% raw %}{{ FOO }} and {% BAR %}{% endraw %}').render(),
          equals('{{ FOO }} and {% BAR %}'));
    });

    test('const', () {
      expect(
          environment
              .fromString('{{ true }}|{{ false }}|{{ none }}|{{ none is defined }}|{{ missing is defined }}')
              .render(),
          equals('true|false|null|true|false'));
    });

    test('neg filter priority', () {
      var template = environment.fromString('{{ -1 | foo }}');
      var output = template.nodes[0] as Output;
      var filter = output.nodes[0];
      expect(filter, isA<Filter>());
      expect((filter as Filter).expression, isA<Neg>());
    });

    test('const assign', () {
      for (var source in ['{% set true = 42 %}', '{% for none in seq %}{% endfor %}']) {
        expect(() => environment.fromString(source), throwsA(isA<TemplateSyntaxError>()));
      }
    });

    test('localset', () {
      expect(
          environment
              .fromString('{% set foo = 0 %}{% for item in [1, 2] %}{% set foo = 1 %}{% endfor %}{{ foo }}')
              .render(),
          equals('0'));
    });

    test('parse unary', () {
      var data = {
        'foo': {'bar': 42}
      };
      expect(environment.fromString('{{ -foo["bar"] }}').render(data), equals('-42'));
      expect(environment.fromString('{{ foo["bar"] }}').render(data), equals('42'));
    });
  });
}
