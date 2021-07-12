import 'dart:math' show Random;

import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

import 'environment.dart';

class User {
  User(this.username);

  final String username;

  String operator [](String key) {
    if (key == 'username') {
      return username;
    }

    throw NoSuchMethodError.withInvocation(this, Invocation.getter(#username));
  }
}

class IntIsh {
  int toInt() {
    return 42;
  }
}

void main() {
  group('Filter', () {
    test('filter calling', () {
      final result = env.callFilter('sum', [1, 2, 3]);
      expect(result, equals(6));
    });

    test('capitalize', () {
      final tmpl = env.fromString('{{ "foo bar"|capitalize }}');
      expect(tmpl.render(), equals('Foo bar'));
    });

    test('center', () {
      final tmpl = env.fromString('{{ "foo"|center(9) }}');
      expect(tmpl.render(), equals('   foo   '));
    });

    test('default', () {
      final tmpl = env
          .fromString('{{ missing|default("no") }}|{{ false|default("no") }}|'
              '{{ false|default("no", true) }}|{{ given|default("no") }}');
      expect(tmpl.render({'given': 'yes'}), equals('no|false|no|yes'));
    });

    // TODO: add test: dictsort
    // test('dictsort', () {});

    test('batch', () {
      final data = {'foo': range(10)};
      var tmpl = env.fromString('{{ foo|batch(3)|list }}');
      var result = tmpl.render(data);
      expect(result, equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]'));
      tmpl = env.fromString('{{ foo|batch(3, "X")|list }}');
      result = tmpl.render(data);
      expect(
          result, equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    // TODO: add test: slice
    // test('slice', () {});

    test('escape', () {
      final tmpl = env.fromString('''{{ '<">&'|escape }}''');
      expect(tmpl.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    // TODO: add test: trim
    // test('trim', () {});

    // add test: striptags
    // test('striptags', () {});

    test('filesizeformat', () {
      var tmpl = env.fromString('{{ 100|filesizeformat }}');
      expect(tmpl.render(), equals('100 Bytes'));
      tmpl = env.fromString('{{ 1000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 kB'));
      tmpl = env.fromString('{{ 1000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 MB'));
      tmpl = env.fromString('{{ 1000000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 GB'));
      tmpl = env.fromString('{{ 1000000000000|filesizeformat }}');
      expect(tmpl.render(), equals('1.0 TB'));
      tmpl = env.fromString('{{ 100|filesizeformat(true) }}');
      expect(tmpl.render(), equals('100 Bytes'));
      tmpl = env.fromString('{{ 1000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('1000 Bytes'));
      tmpl = env.fromString('{{ 1000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('976.6 KiB'));
      tmpl = env.fromString('{{ 1000000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('953.7 MiB'));
      tmpl = env.fromString('{{ 1000000000000|filesizeformat(true) }}');
      expect(tmpl.render(), equals('931.3 GiB'));
    });

    test('first', () {
      final tmpl = env.fromString('{{ foo|first }}');
      expect(tmpl.render({'foo': range(10)}), equals('0'));
    });

    test('float', () {
      final tmpl = env.fromString('{{ value|float }}');
      expect(tmpl.render({'value': '42'}), equals('42.0'));
      expect(tmpl.render({'value': 'abc'}), equals('0.0'));
      expect(tmpl.render({'value': '32.32'}), equals('32.32'));
    });

    test('float default', () {
      final tmpl = env.fromString('{{ value|float(default=1.0) }}');
      expect(tmpl.render({'value': 'abc'}), equals('1.0'));
    });

    // TODO: add test: format
    // test('format', () {});

    // TODO: add test: indent
    // test('indent', () {});

    // TODO: add test: indent markup input
    // test('indent markup input', () {});

    // TODO: add test: indent width string
    // test('indent width string', () {});

    test('int', () {
      // no bigint '12345678901234567890': '12345678901234567890'
      final tmpl = env.fromString('{{ value|int }}');
      expect(tmpl.render({'value': '42'}), equals('42'));
      expect(tmpl.render({'value': 'abc'}), equals('0'));
      expect(tmpl.render({'value': '32.32'}), equals('32'));
    });

    test('int base', () {
      var tmpl = env.fromString('{{ value|int(base=16) }}');
      expect(tmpl.render({'value': '0x4d32'}), equals('19762'));
      tmpl = env.fromString('{{ value|int(base=8) }}');
      expect(tmpl.render({'value': '011'}), equals('9'));
      tmpl = env.fromString('{{ value|int(base=16) }}');
      expect(tmpl.render({'value': '0x33Z'}), equals('0'));
    });

    test('int default', () {
      final tmpl = env.fromString('{{ value|int(default=1) }}');
      expect(tmpl.render({'value': 'abc'}), equals('1'));
    });

    test('int special method', () {
      final tmpl = env.fromString('{{ value|int }}');
      expect(tmpl.render({'value': IntIsh()}), equals('42'));
    });

    test('join', () {
      var tmpl = env.fromString('{{ [1, 2, 3]|join("|") }}');
      expect(tmpl.render(), equals('1|2|3'));
      var env2 = Environment(autoEscape: true);
      tmpl = env2.fromString('{{ ["<foo>", "<span>foo</span>"|safe]|join }}');
      expect(tmpl.render(), equals('&lt;foo&gt;<span>foo</span>'));
    });

    test('join attribute', () {
      final tmpl = env.fromString('{{ users|join(", ", "username") }}');
      final users = [User('foo'), User('bar')];
      expect(tmpl.render({'users': users}), equals('foo, bar'));
    });

    test('last', () {
      final tmpl = env.fromString('''{{ foo|last }}''');
      expect(tmpl.render({'foo': range(10)}), equals('9'));
    });

    test('length', () {
      final tmpl = env.fromString('{{ "hello world"|length }}');
      expect(tmpl.render(), equals('11'));
    });

    test('lower', () {
      final tmpl = env.fromString('''{{ "FOO"|lower }}''');
      expect(tmpl.render(), equals('foo'));
    });

    test('pprint', () {
      final tmpl = env.fromString('{{ value|pprint }}');
      final list = <int>[for (var i = 0; i < 10; i += 1) i];
      expect(tmpl.render({'value': list}), equals(format(list)));
    });

    test('random', () {
      final expected = '1234567890';
      final random = Random(0);
      final env = Environment(random: Random(0));
      final tmpl = env.fromString('{{ "$expected"|random }}');

      for (var i = 0; i < 10; i += 1) {
        expect(tmpl.render(), equals(expected[random.nextInt(10)]));
      }
    });

    test('reverse', () {
      var tmpl = env.fromString(
          '{{ "foobar"|reverse|join }}|{{ [1, 2, 3]|reverse|list }}');
      expect(tmpl.render(), equals('raboof|[3, 2, 1]'));
    });

    test('string', () {
      final values = [1, 2, 3, 4, 5];
      final tmpl = env.fromString('{{ values|string }}');
      expect(tmpl.render({'values': values}), equals('$values'));
    });

    // TODO: add test: truncate
    // test('truncate', () {});

    // TODO: add test: title
    // test('title', () {});

    // TODO: add test: truncate
    // test('truncate', () {});

    // TODO: add test: truncate very short
    // test('truncate very short', () {});

    // TODO: add test: truncate end length
    // htest('truncate end lengthh', () {});

    test('upper', () {
      final tmpl = env.fromString('{{ "foo"|upper }}');
      expect(tmpl.render(), equals('FOO'));
    });

    // TODO: add test: urlize
    // test('urlize', () {});

    // TODO: add test: urlize rel policy
    // test('urlize rel policy', () {});

    // TODO: add test: urlize target parameter
    // test('urlize target parameter', () {});

    // TODO: add test: urlize extra schemes parameter
    // test('urlize extra schemes parameter', () {});

    test('wordcount', () {
      final tmpl = env.fromString('{{ "foo bar baz"|wordcount }}');
      expect(tmpl.render(), equals('3'));
    });

    // TODO: add test: block
    // test('block', () {});

    test('chaining', () {
      final tmpl =
          env.fromString('{{ ["<foo>", "<bar>"]|first|upper|escape }}');
      expect(tmpl.render(), equals('&lt;FOO&gt;'));
    });

    // TODO: add test: sum
    // test('sum', () {});

    // TODO: add test: sum attributes
    // test('sum attributes', () {});

    // TODO: add test: sum attributes nested
    // test('sum attributes nested', () {});

    // TODO: add test: sum attributes tuple
    // test('sum attributes tuple', () {});

    // TODO: add test: abs
    // test('abs', () {});

    // TODO: add test: round positive
    // test('round positive', () {});

    // TODO: add test: round negative
    // test('round negative', () {});

    // TODO: add test: xmlattr
    // test('xmlattr', () {});

    // TODO: add test: sortN
    // test('sortN', () {});

    // TODO: add test: unique
    // test('unique', () {});

    // TODO: add test: unique case sensitive
    // test('unique case sensitive', () {});

    // TODO: add test: unique attribute
    // test('unique attribute', () {});

    // TODO: add test: min max
    // test('min max', () {});

    // TODO: add test: min max attribute
    // test('min max attribute', () {});

    // TODO: add test: groupby
    // test('groupby', () {});

    // TODO: add test: groupby tuple index
    // test('groupby tuple index', () {});

    // TODO: add test: groupby multidot
    // test('groupby multidot', () {});

    // TODO: add test: groupby default
    // test('groupby default', () {});

    // TODO: add test: filtertag
    // test('filtertag', () {});

    // TODO: add test: replace
    // test('replace', () {});

    test('force escape', () {
      final tmpl = env.fromString('{{ x|forceescape }}');
      expect(tmpl.render({'x': Markup.escaped('<div />')}),
          equals('&lt;div /&gt;'));
    });

    test('safe', () {
      final env = Environment(autoEscape: true);
      var tmpl = env.fromString('{{ "<div>foo</div>"|safe }}');
      expect(tmpl.render(), equals('<div>foo</div>'));
      tmpl = env.fromString('{{ "<div>foo</div>" }}');
      expect(tmpl.render(), equals('&lt;div&gt;foo&lt;/div&gt;'));
    });

    // TODO: add test: url encode
    // test('url encode', () {});

    // TODO: add test: simple map
    // test('simple map', () {});

    // TODO: add test: map sum
    // test('map sum', () {});

    // TODO: add test: attribute map
    // test('attribute map', () {});

    // TODO: add test: empty map
    // test('empty map', () {});

    // TODO: add test: map default
    // test('map default', () {});

    // TODO: add test: simple select
    // test('simple select', () {});

    // TODO: add test: bool select
    // test('bool select', () {});

    // TODO: add test: simple reject
    // test('simple reject', () {});

    // TODO: add test: simple reject attr
    // test('simple reject attr', () {});

    // TODO: add test: func select attr
    // test('func select attr', () {});

    // TODO: add test: func reject attr
    // test('func reject attr', () {});

    // TODO: add test: json dump
    // test('json dump', () {});

    // TODO: add test: map default
    // test('map default', () {});

    test('wordwrap', () {
      final env = Environment(newLine: '\n');
      final tmpl = env.fromString('{{ string|wordwrap(20) }}');
      final result =
          tmpl.render({'string': 'Hello!\nThis is Jinja saying something.'});
      expect(result, equals('Hello!\nThis is Jinja saying\nsomething.'));
    });

    // TODO: add test: filter undefined
    // test('filter undefined', () {});

    // TODO: add test: filter undefined in if
    // test('filter undefined in if', () {});

    // TODO: add test: filter undefined in elif
    // test('filter undefined in elif', () {});

    // TODO: add test: filter undefined in else
    // test('filter undefined in else', () {});

    // TODO: add test: filter undefined in nested if
    // test('filter undefined in nested if', () {});

    // TODO: add test: filter undefined in cond expr
    // test('filter undefined in cond expr', () {});
  });
}
