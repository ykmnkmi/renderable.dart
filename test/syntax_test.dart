import 'package:renderable/jinja.dart';
import 'package:renderable/src/nodes.dart';
import 'package:renderable/src/utils.dart';
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
      expect(template.render({'foo': {'bar': 42}}), equals('42|42'));
    });

    test('subscript', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo[0] }}|{{ foo[-1] }}');
      expect(template.render({'foo': [0, 1, 2]}), equals('0|2'));
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
      final environment = Environment();
      final matches = {'>': [1, 0], '>=': [1, 1], '<': [2, 3], '<=': [3, 4], '==': [4, 4], '!=': [4, 5]};

      matches.forEach((operation, pair) {
        final template = environment.fromString('{{ ${pair.first} $operation ${pair.last} }}');
        expect(template.render(), equals('true'));
      });
    });

    test('compare parens', () {
      final environment = Environment();
      // num * bool not supported
      // '{{ i * (j < 5) }}'
      final template = environment.fromString('{{ i == (j < 5) }}');
      expect(template.render({'i': 2, 'j': 3}), equals('false'));
    });

    test('compare compound', () {
      final environment = Environment();
      final matches = {
        '{{ 4 < 2 < 3 }}': 'false',
        '{{ a < b < c }}': 'false',
        '{{ 4 > 2 > 3 }}': 'false',
        '{{ a > b > c }}': 'false',
        '{{ 4 > 2 < 3 }}': 'true',
        '{{ a > b < c }}': 'true',
      };

      matches.forEach((source, expekt) {
        final template = environment.fromString(source);
        expect(template.render({'a': 4, 'b': 2, 'c': 3}), equals(expekt));
      });
    });

    test('inop', () {
      final environment = Environment();
      final template = environment.fromString('{{ 1 in [1, 2, 3] }}|{{ 1 not in [1, 2, 3] }}');
      expect(template.render(), equals('true|false'));
    });

    test('collection literal', () {
      final environment = Environment();
      final matches = {'[]': '[]', '{}': '{}', '()': '[]'}; // tuple is list

      matches.forEach((source, expekt) {
        final template = environment.fromString('{{ $source }}');
        expect(template.render(), equals(expekt));
      });
    });

    test('numeric literal', () {
      final environment = Environment();
      final matches = {
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
        final template = environment.fromString('{{ $source }}');
        expect(template.render(), equals(expekt));
      });
    });

    test('bool', () {
      final environment = Environment();
      final template = environment.fromString('{{ true and false }}|{{ false or true }}|{{ not false }}');
      expect(template.render(), equals('false|true|true'));
    });

    test('grouping', () {
      final environment = Environment();
      final template = environment.fromString('{{ (true and false) or (false and true) and not false }}');
      expect(template.render(), equals('false'));
    });

    test('django attr', () {
      final environment = Environment();
      final template = environment.fromString('{{ [1, 2, 3].0 }}|{{ [[1]].0.0 }}');
      expect(template.render(), equals('1|1'));
    });

    test('conditional expression', () {
      final environment = Environment();
      final template = environment.fromString('{{ 0 if true else 1 }}');
      expect(template.render(), equals('0'));
    });

    test('short conditional expression', () {
      final environment = Environment();
      final template = environment.fromString('<{{ 1 if false }}>');
      expect(template.render(), equals('<>'));
    });

    test('filter priority', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foo" | upper + "bar" | upper }}');
      expect(template.render(), equals('FOOBAR'));
    });

    test('function calls', () {
      final environment = Environment();
      final matches = {
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
      final environment = Environment();
      final sources = {
        '{{ () }}',
        '{{ (1, 2) }}',
        '{{ (1, 2,) }}',
        '{{ 1, }}',
        '{{ 1, 2 }}',
        '{% for foo, bar in seq %}...{% endfor %}',
        '{% for x in foo, bar %}...{% endfor %}',
        '{% for x in foo, %}...{% endfor %}',
      };

      sources.forEach((source) {
        expect(environment.fromString(source), isA<Template>());
      });
    });

    test('triling comma', () {
      final environment = Environment();
      final template = environment.fromString('{{ (1, 2,) }}|{{ [1, 2,] }}|{{ {1: 2,} }}');
      // tuple is list
      expect(template.render(), equals('[1, 2]|[1, 2]|{1: 2}'));
    });

    test('block end name', () {
      final environment = Environment();
      expect(environment.fromString('{% block foo %}...{% endblock foo %}'), isA<Template>());
      expect(() => environment.fromString('{% block x %}{% endblock y %}'), throwsA(isA<TemplateSyntaxError>()));
    }, skip: true);

    test('constant casing', () {
      final environment = Environment();

      for (final constant in [true, false, null]) {
        final string = constant.toString();
        final template = environment.fromString('{{ $string }}|{{ ${string.toLowerCase()} }}|{{ ${string.toUpperCase()} }}');
        expect(template.render(), equals('$constant|$constant|'));
      }
    });

    test('string concatenation', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foo" "bar" "baz" }}');
      expect(template.render(), equals('foobarbaz'));
    });

    test('notin', () {
      final environment = Environment();
      final template = environment.fromString('{{ not 42 in bar }}');
      expect(template.render({'bar': range(100)}), equals('false'));
    });

    test('operator precedence', () {
      final environment = Environment();
      final template = environment.fromString('{{ 2 * 3 + 4 % 2 + 1 - 2 }}');
      expect(template.render(), equals('5'));
    });

    test('implicit subscribed tuple', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo[1, 2] }}');
      // tuple is list
      expect(template.render({'foo': Foo()}), equals('[1, 2]'));
    });

    test('raw2', () {
      final environment = Environment();
      final template = environment.fromString('{% raw %}{{ FOO }} and {% BAR %}{% endraw %}');
      // tuple is list
      expect(template.render(), equals('{{ FOO }} and {% BAR %}'));
    });

    test('const', () {
      final environment = Environment();
      final template = environment.fromString('{{ true }}|{{ false }}|{{ none }}|{{ none is defined }}|{{ missing is defined }}');
      expect(template.render(), equals('true|false|null|true|false'));
    });

    test('neg filter priority', () {
      final environment = Environment();
      final template = environment.fromString('{{ -1 | foo }}');
      expect((template.nodes[0] as Output).nodes[0], isA<Filter>());
      expect(((template.nodes[0] as Output).nodes[0] as Filter).expression, isA<Neg>());
    });

    test('const assign', () {
      final environment = Environment();

      for (final source in ['{% set true = 42 %}', '{% for none in seq %}{% endfor %}']) {
        expect(() => environment.fromString(source), throwsA(isA<TemplateSyntaxError>()));
      }
    });

    test('localset', () {
      final environment = Environment();
      final template = environment.fromString('{% set foo = 0 %}{% for item in [1, 2] %}{% set foo = 1 %}{% endfor %}{{ foo }}');
      expect(template.render(), equals('0'));
    });

    test('parse unary', () {
      final environment = Environment();
      var template = environment.fromString('{{ -foo["bar"] }}');
      expect(template.render({'foo': {'bar': 42}}), equals('-42'));
      template = environment.fromString('{{ foo["bar"] }}');
      expect(template.render({'foo': {'bar': 42}}), equals('42'));
    });
  });
}

class Foo {
  Object? operator [](Object? key) {
    return key;
  }
}
