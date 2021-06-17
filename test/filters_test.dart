import 'dart:math' show Random;

import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';

import 'core.dart';

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
    late Environment environment;

    setUpAll(() {
      environment = Environment();
    });

    test('filter calling', () {
      environment.callFilter('sum', <int>[1, 2, 3]).equals(6);
    });

    test('capitalize', () {
      environment.fromString('{{ "foo bar" | capitalize }}').render().equals('Foo bar');
    });

    test('center', () {
      environment.fromString('{{ "foo" | center(9) }}').render().equals('   foo   ');
    });

    test('default', () {
      var data = <String, Object?>{'given': 'yes'};
      environment
          .fromString('{{ missing | default("no") }}|{{ false | default("no") }}|'
              '{{ false | default("no", true) }}|{{ given | default("no") }}')
          .render(data)
          .equals('no|false|no|yes');
    });

    test('dictsort', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('batch', () {
      var data = <String, Object?>{'foo': range(10)};
      environment
          .fromString('{{ foo | batch(3) | list }}|{{ foo | batch(3, "X") | list }}')
          .render(data)
          .equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]');
    });

    test('slice', () {
      throw UnimplementedError('slice');
    }, skip: true);

    test('escape', () {
      environment.fromString('''{{ '<">&'|escape }}''').render().equals('&lt;&#34;&gt;&amp;');
    });

    test('trim', () {
      throw UnimplementedError('trim');
    }, skip: true);

    test('striptags', () {
      throw UnimplementedError('dictsort');
    }, skip: true);

    test('filesizeformat', () {
      environment
          .fromString('{{ 100 | filesizeformat }}|'
              '{{ 1000 | filesizeformat }}|'
              '{{ 1000000 | filesizeformat }}|'
              '{{ 1000000000 | filesizeformat }}|'
              '{{ 1000000000000 | filesizeformat }}|'
              '{{ 100 | filesizeformat(true) }}|'
              '{{ 1000 | filesizeformat(true) }}|'
              '{{ 1000000 | filesizeformat(true) }}|'
              '{{ 1000000000 | filesizeformat(true) }}|'
              '{{ 1000000000000 | filesizeformat(true) }}')
          .render()
          .equals('100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB');
    });

    test('first', () {
      var data = <String, Object?>{'foo': range(10)};
      environment.fromString('{{ foo | first }}').render(data).equals('0');
    });

    test('float', () {
      var matches = {'42': '42.0', 'abc': '0.0', '32.32': '32.32'};
      var tempalte = environment.fromString('{{ value | float }}');

      matches.forEach((value, expekt) {
        var data = <String, Object?>{'value': value};
        tempalte.render(data).equals(expekt);
      });
    });

    test('float default', () {
      var data = <String, Object?>{'value': 'abc'};
      environment.fromString('{{ value | float(default=1.0) }}').render(data).equals('1.0');
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
      var matches = {'42': '42', 'abc': '0', '32.32': '32'};
      var template = environment.fromString('{{ value | int }}');

      matches.forEach((value, expekt) {
        var data = <String, Object?>{'value': value};
        template.render(data).equals(expekt);
      });
    });

    test('int base', () {
      var matches = {
        '0x4d32': [16, '19762'],
        '011': [8, '9'],
        '0x33Z': [16, '0'],
      };

      matches.forEach((value, match) {
        var data = <String, Object?>{'value': value};
        environment.fromString('{{ value | int(base=${match[0]}) }}').render(data).equals(match[1]);
      });
    });

    test('int default', () {
      var data = <String, Object?>{'value': 'abc'};
      environment.fromString('{{ value | int(default=1) }}').render(data).equals('1');
    });

    test('int special method', () {
      var data = <String, Object?>{'value': IntIsh()};
      environment.fromString('{{ value | int }}').render(data).equals('42');
    });

    test('join', () {
      environment.fromString('{{ [1, 2, 3] | join("|") }}').render().equals('1|2|3');
      Environment(autoEscape: true)
          .fromString('{{ ["<foo>", "<span>foo</span>" | safe] | join }}')
          .render()
          .equals('&lt;foo&gt;<span>foo</span>');
    });

    test('join attribute', () {
      var data = <String, Object?>{
        'users': <Map<String, Object?>>[
          <String, Object?>{'username': 'foo'},
          <String, Object?>{'username': 'bar'},
        ]
      };
      environment.fromString('{{ users | join(", ", "username") }}').render(data).equals('foo, bar');
    });

    test('last', () {
      var data = <String, Object?>{'foo': range(10)};
      environment.fromString('''{{ foo | last }}''').render(data).equals('9');
    });

    test('length', () {
      environment.fromString('{{ "hello world" | length }}').render().equals('11');
    });

    test('lower', () {
      environment.fromString('''{{ "FOO" | lower }}''').render().equals('foo');
    });

    test('pprint', () {
      var list = List.generate(10, (index) => index);
      var data = <String, Object?>{'value': list};
      environment.fromString('{{ value | pprint }}').render(data).equals(format(list));
    });

    test('random', () {
      var numbers = '1234567890';
      var template = Environment(random: Random(0)).fromString('{{ "$numbers" | random }}');
      var random = Random(0);

      for (var i = 0; i < 10; i += 1) {
        template.render().equals(numbers[random.nextInt(10)]);
      }
    });

    test('reverse', () {
      environment
          .fromString('{{ "foobar" | reverse | join }}|{{ [1, 2, 3] | reverse | list }}')
          .render()
          .equals('raboof|[3, 2, 1]');
    });

    test('string', () {
      var values = <int>[1, 2, 3, 4, 5];
      var data = <String, Object?>{'values': values};
      environment.fromString('{{ values | string }}').render(data).equals('$values');
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
      environment.fromString('{{ "foo" | upper }}').render().equals('FOO');
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
      environment.fromString('{{ "foo bar baz" | wordcount }}').render().equals('3');
    });

    test('block', () {
      throw UnimplementedError('block');
    }, skip: true);

    test('chaining', () {
      environment.fromString('{{ ["<foo>", "<bar>"]| first | upper | escape }}').render().equals('&lt;FOO&gt;');
    });

    test('force escape', () {
      var data = <String, Object?>{'x': Markup.escaped('<div />')};
      environment.fromString('{{ x | forceescape }}').render(data).equals('&lt;div /&gt;');
    });

    test('safe', () {
      var environment = Environment(autoEscape: true);
      environment.fromString('{{ "<div>foo</div>" | safe }}').render().equals('<div>foo</div>');
      environment.fromString('{{ "<div>foo</div>" }}').render().equals('&lt;div&gt;foo&lt;/div&gt;');
    });

    test('wordwrap', () {
      var data = <String, Object?>{'string': 'Hello!\nThis is Jinja saying something.'};
      Environment(newLine: '\n')
          .fromString('{{ string | wordwrap(20) }}')
          .render(data)
          .equals('Hello!\nThis is Jinja saying\nsomething.');
    });
  });
}
