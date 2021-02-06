import 'dart:math' show Random;

import 'package:renderable/jinja.dart';
import 'package:renderable/markup.dart';
import 'package:renderable/utils.dart';
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
    test('filter calling', () {
      final environment = Environment();
      expect(environment.callFilter('sum', <int>[1, 2, 3]), equals(6));
    });

    test('capitalize', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foo bar" | capitalize }}');
      expect(template.render(), equals('Foo bar'));
    });

    test('center', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foo" | center(9) }}');
      expect(template.render(), equals('   foo   '));
    });

    test('default', () {
      final environment = Environment();
      final template = environment.fromString('{{ missing | default("no") }}|{{ false | default("no") }}|'
          '{{ false | default("no", true) }}|{{ given | default("no") }}');
      expect(template.render(<String, Object>{'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('dictsort', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('batch', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo | batch(3) | list }}|{{ foo | batch(3, "X") | list }}');
      expect(
        template.render(<String, Object>{'foo': range(10)}),
        equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'),
      );
    });

    test('slice', () {
      throw UnimplementedError('slice');
    }, skip: true);

    test('escape', () {
      final environment = Environment();
      final template = environment.fromString('''{{ '<">&'|escape }}''');
      expect(template.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('trim', () {
      throw UnimplementedError('trim');
    }, skip: true);

    test('striptags', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('filesizeformat', () {
      final environment = Environment();
      final template = environment.fromString('{{ 100 | filesizeformat }}|'
          '{{ 1000 | filesizeformat }}|'
          '{{ 1000000 | filesizeformat }}|'
          '{{ 1000000000 | filesizeformat }}|'
          '{{ 1000000000000 | filesizeformat }}|'
          '{{ 100 | filesizeformat(true) }}|'
          '{{ 1000 | filesizeformat(true) }}|'
          '{{ 1000000 | filesizeformat(true) }}|'
          '{{ 1000000000 | filesizeformat(true) }}|'
          '{{ 1000000000000 | filesizeformat(true) }}');
      expect(template.render(), equals('100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB'));
    });

    test('first', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo | first }}');
      expect(template.render(<String, Object>{'foo': range(10)}), equals('0'));
    });

    test('float', () {
      final environment = Environment();
      final matches = {'42': '42.0', 'abc': '0.0', '32.32': '32.32'};

      matches.forEach((value, expekt) {
        final template = environment.fromString('{{ value | float }}');
        expect(template.render(<String, Object>{'value': value}), equals(expekt));
      });
    });

    test('float default', () {
      final environment = Environment();
      final template = environment.fromString('{{ value | float(default=1.0) }}');
      expect(template.render(<String, Object>{'value': 'abc'}), equals('1.0'));
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
      final environment = Environment();
      final matches = {
        '42': '42',
        'abc': '0',
        '32.32': '32',
        // no bigint
        // '12345678901234567890': '12345678901234567890'
      };

      matches.forEach((value, expekt) {
        final template = environment.fromString('{{ value | int }}');
        expect(template.render(<String, Object>{'value': value}), equals(expekt));
      });
    });

    test('int base', () {
      final environment = Environment();
      final matches = {
        '0x4d32': [16, '19762'],
        '011': [8, '9'],
        '0x33Z': [16, '0'],
      };

      matches.forEach((value, match) {
        final base = match.first;
        final expekt = match.last;
        final template = environment.fromString('{{ value | int(base=$base) }}');
        expect(template.render(<String, Object>{'value': value}), equals(expekt));
      });
    });

    test('int default', () {
      final environment = Environment();
      final template = environment.fromString('{{ value | int(default=1) }}');
      expect(template.render(<String, Object>{'value': 'abc'}), equals('1'));
    });

    test('int special method', () {
      final environment = Environment();
      final template = environment.fromString('{{ value | int }}');
      expect(template.render(<String, Object>{'value': IntIsh()}), equals('42'));
    });

    test('join', () {
      var environment = Environment();
      var template = environment.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.render(), equals('1|2|3'));

      environment = Environment(autoEscape: true);
      template = environment.fromString('{{ ["<foo>", "<span>foo</span>" | safe] | join }}');
      expect(template.render(), equals('&lt;foo&gt;<span>foo</span>'));
    });

    test('join attribute', () {
      final environment = Environment();
      final template = environment.fromString('{{ users | join(", ", "username") }}');
      final users = [
        {'username': 'foo'},
        {'username': 'bar'},
      ];

      expect(template.render(<String, Object>{'users': users}), equals('foo, bar'));
    });

    test('last', () {
      final environment = Environment();
      final template = environment.fromString('''{{ foo | last }}''');
      expect(template.render(<String, Object>{'foo': range(10)}), equals('9'));
    });

    test('length', () {
      final environment = Environment();
      final template = environment.fromString('{{ "hello world" | length }}');
      expect(template.render(), equals('11'));
    });

    test('lower', () {
      final environment = Environment();
      final template = environment.fromString('''{{ "FOO" | lower }}''');
      expect(template.render(), equals('foo'));
    });

    test('pprint', () {
      final environment = Environment();
      final template = environment.fromString('{{ data | pprint }}');
      final data = List<int>.generate(10, (index) => index);
      expect(template.render(<String, Object>{'data': data}), equals(format(data)));
    });

    test('random', () {
      final random = Random(0);
      final numbers = '1234567890';
      final expekted = [for (var i = 0; i < 10; i += 1) numbers[random.nextInt(10)]];
      final environment = Environment(random: Random(0));
      final template = environment.fromString('{{ "$numbers" | random }}');

      for (final value in expekted) {
        expect(template.render(), equals(value));
      }
    });

    test('reverse', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foobar" | reverse | join }}|{{ [1, 2, 3] | reverse | list }}');
      expect(template.render(), equals('raboof|[3, 2, 1]'));
    });

    test('string', () {
      final values = [1, 2, 3, 4, 5];
      final environment = Environment();
      final template = environment.fromString('{{ values | string }}');
      expect(template.render(<String, Object>{'values': values}), equals('$values'));
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
      final environment = Environment();
      final template = environment.fromString('{{ "foo" | upper }}');
      expect(template.render(), equals('FOO'));
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

    test('word count', () {
      throw UnimplementedError('word count');
    }, skip: true);

    test('block', () {
      throw UnimplementedError('block');
    }, skip: true);

    test('chaining', () {
      final environment = Environment();
      final template = environment.fromString('{{ ["<foo>", "<bar>"]| first | upper | escape }}');
      expect(template.render(), equals('&lt;FOO&gt;'));
    });

    test('force escape', () {
      final environment = Environment();
      final template = environment.fromString('{{ x | forceescape }}');
      expect(template.render(<String, Object>{'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });

    test('safe', () {
      final environment = Environment(autoEscape: true);
      var template = environment.fromString('{{ "<div>foo</div>" | safe }}');
      expect(template.render(), equals('<div>foo</div>'));
      template = environment.fromString('{{ "<div>foo</div>" }}');
      expect(template.render(), equals('&lt;div&gt;foo&lt;/div&gt;'));
    });
  });
}
