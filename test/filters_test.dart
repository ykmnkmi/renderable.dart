import 'dart:math' show Random;

import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

class User {
  User(this.name);

  final String name;
}

class IntIsh {
  int toInt() {
    return 42;
  }
}

void main() {
  group('Filter', () {
    late final environment = Environment();

    test('filter calling', () {
      expect(environment.callFilter('sum', [1, 2, 3]), equals(6));
    });

    test('capitalize', () {
      expect(environment.fromString('{{ "foo bar" | capitalize }}').render(), equals('Foo bar'));
    });

    test('center', () {
      expect(environment.fromString('{{ "foo" | center(9) }}').render(), equals('   foo   '));
    });

    test('default', () {
      var source = '{{ missing | default("no") }}|{{ false | default("no") }}|'
          '{{ false | default("no", true) }}|{{ given | default("no") }}';
      expect(environment.fromString(source).render({'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('dictsort', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('batch', () {
      var source = '{{ foo | batch(3) | list }}|{{ foo | batch(3, "X") | list }}';
      var result = environment.fromString(source).render({'foo': range(10)});
      expect(result, equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    test('slice', () {
      throw UnimplementedError('slice');
    }, skip: true);

    test('escape', () {
      expect(environment.fromString('''{{ '<">&'|escape }}''').render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('trim', () {
      throw UnimplementedError('trim');
    }, skip: true);

    test('striptags', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('filesizeformat', () {
      expect(environment.fromString('{{ 100 | filesizeformat }}').render(), equals('100 Bytes'));
      expect(environment.fromString('{{ 1000 | filesizeformat }}').render(), equals('1.0 kB'));
      expect(environment.fromString('{{ 1000000 | filesizeformat }}').render(), equals('1.0 MB'));
      expect(environment.fromString('{{ 1000000000 | filesizeformat }}').render(), equals('1.0 GB'));
      expect(environment.fromString('{{ 1000000000000 | filesizeformat }}').render(), equals('1.0 TB'));
      expect(environment.fromString('{{ 100 | filesizeformat(true) }}').render(), equals('100 Bytes'));
      expect(environment.fromString('{{ 1000 | filesizeformat(true) }}').render(), equals('1000 Bytes'));
      expect(environment.fromString('{{ 1000000 | filesizeformat(true) }}').render(), equals('976.6 KiB'));
      expect(environment.fromString('{{ 1000000000 | filesizeformat(true) }}').render(), equals('953.7 MiB'));
      expect(environment.fromString('{{ 1000000000000 | filesizeformat(true) }}').render(), equals('931.3 GiB'));
    });

    test('first', () {
      expect(environment.fromString('{{ foo | first }}').render({'foo': range(10)}), equals('0'));
    });

    test('float', () {
      var template = environment.fromString('{{ value | float }}');
      expect(template.render({'value': '42'}), equals('42.0'));
      expect(template.render({'value': 'abc'}), equals('0.0'));
      expect(template.render({'value': '32.32'}), equals('32.32'));
    });

    test('float default', () {
      expect(environment.fromString('{{ value | float(default=1.0) }}').render({'value': 'abc'}), equals('1.0'));
    });

    test('format', () {
      throw UnimplementedError('format');
    }, skip: true);

    test('indent', () {
      throw UnimplementedError('indent');
    }, skip: true);

    test('indent markup input', () {
      throw UnimplementedError('test indent markup input not added');
    }, skip: true);

    test('int', () {
      // no bigint '12345678901234567890': '12345678901234567890'
      var template = environment.fromString('{{ value | int }}');
      expect(template.render({'value': '42'}), equals('42'));
      expect(template.render({'value': 'abc'}), equals('0'));
      expect(template.render({'value': '32.32'}), equals('32'));
    });

    test('int base', () {
      expect(environment.fromString('{{ value | int(base=16) }}').render({'value': '0x4d32'}), equals('19762'));
      expect(environment.fromString('{{ value | int(base=8) }}').render({'value': '011'}), equals('9'));
      expect(environment.fromString('{{ value | int(base=16) }}').render({'value': '0x33Z'}), equals('0'));
    });

    test('int default', () {
      expect(environment.fromString('{{ value | int(default=1) }}').render({'value': 'abc'}), equals('1'));
    });

    test('int special method', () {
      expect(environment.fromString('{{ value | int }}').render({'value': IntIsh()}), equals('42'));
    });

    test('join', () {
      expect(environment.fromString('{{ [1, 2, 3] | join("|") }}').render(), equals('1|2|3'));
      var source = '{{ ["<foo>", "<span>foo</span>" | safe] | join }}';
      expect(Environment(autoEscape: true).fromString(source).render(), equals('&lt;foo&gt;<span>foo</span>'));
    });

    test('join attribute', () {
      var data = {
        'users': [
          {'username': 'foo'},
          {'username': 'bar'},
        ]
      };

      expect(environment.fromString('{{ users | join(", ", "username") }}').render(data), equals('foo, bar'));
    });

    test('last', () {
      expect(environment.fromString('''{{ foo | last }}''').render({'foo': range(10)}), equals('9'));
    });

    test('length', () {
      expect(environment.fromString('{{ "hello world" | length }}').render(), equals('11'));
    });

    test('lower', () {
      expect(environment.fromString('''{{ "FOO" | lower }}''').render(), equals('foo'));
    });

    test('pprint', () {
      var list = List.generate(10, (index) => index);
      expect(environment.fromString('{{ value | pprint }}').render({'value': list}), equals(format(list)));
    });

    test('random', () {
      var numbers = '1234567890';
      var template = Environment(random: Random(0)).fromString('{{ "$numbers" | random }}');
      var random = Random(0);

      for (var i = 0; i < 10; i += 1) {
        expect(template.render(), equals(numbers[random.nextInt(10)]));
      }
    });

    test('reverse', () {
      var source = '{{ "foobar" | reverse | join }}|{{ [1, 2, 3] | reverse | list }}';
      expect(environment.fromString(source).render(), equals('raboof|[3, 2, 1]'));
    });

    test('string', () {
      var values = [1, 2, 3, 4, 5];
      expect(environment.fromString('{{ values | string }}').render({'values': values}), equals('$values'));
    });

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('title', () {
      throw UnimplementedError('title');
    }, skip: true);

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('truncate very short', () {
      throw UnimplementedError('truncate very short');
    }, skip: true);

    test('truncate', () {
      throw UnimplementedError('truncate');
    }, skip: true);

    test('truncate end length', () {
      throw UnimplementedError('truncate end length');
    }, skip: true);

    test('upper', () {
      expect(environment.fromString('{{ "foo" | upper }}').render(), equals('FOO'));
    });

    test('urlize', () {
      throw UnimplementedError('urlize');
    }, skip: true);

    test('urlize rel policy', () {
      throw UnimplementedError('urlize rel policy');
    }, skip: true);

    test('urlize target parameter', () {
      throw UnimplementedError('urlize target parameter');
    }, skip: true);

    test('wordcount', () {
      expect(environment.fromString('{{ "foo bar baz" | wordcount }}').render(), equals('3'));
    });

    test('block', () {
      throw UnimplementedError('block');
    }, skip: true);

    test('chaining', () {
      var result = environment.fromString('{{ ["<foo>", "<bar>"]| first | upper | escape }}').render();
      expect(result, equals('&lt;FOO&gt;'));
    });

    test('force escape', () {
      var result = environment.fromString('{{ x | forceescape }}').render({'x': Markup.escaped('<div />')});
      expect(result, equals('&lt;div /&gt;'));
    });

    test('safe', () {
      var environment = Environment(autoEscape: true);
      expect(environment.fromString('{{ "<div>foo</div>" | safe }}').render(), equals('<div>foo</div>'));
      expect(environment.fromString('{{ "<div>foo</div>" }}').render(), equals('&lt;div&gt;foo&lt;/div&gt;'));
    });

    test('wordwrap', () {
      var string = 'Hello!\nThis is Jinja saying something.';
      var result = Environment(newLine: '\n').fromString('{{ string | wordwrap(20) }}').render({'string': string});
      expect(result, equals('Hello!\nThis is Jinja saying\nsomething.'));
    });
  });
}
