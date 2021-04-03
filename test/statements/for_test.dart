import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

const Map<String, List<Map<String, Object>>> recursiveData = <String, List<Map<String, Object>>>{
  'seq': <Map<String, Object>>[
    {
      'a': 1,
      'b': [
        {'a': 1},
        {'a': 2}
      ]
    },
    {
      'a': 2,
      'b': [
        {'a': 1},
        {'a': 2}
      ]
    },
    {
      'a': 3,
      'b': [
        {'a': 'a'}
      ]
    },
  ]
};

void main() {
  group('For', () {
    test('simple', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in seq %}{{ item }}{% endfor %}');
      expect(template.render({'seq': range(10)}), equals('0123456789'));
    });

    test('else', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in seq %}XXX{% else %}...{% endfor %}');
      expect(template.render(), equals('...'));
    });

    test('else scoping item', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in [] %}{% else %}{{ item }}{% endfor %}');
      expect(template.render({'item': 42}), equals('42'));
    });

    test('empty blocks', () {
      final environment = Environment();
      final template = environment.fromString('<{% for item in seq %}{% else %}{% endfor %}>');
      expect(template.render(), equals('<>'));
    });

    test('context vars', () {
      final environment = Environment();
      Template template;

      final slist = [42, 24];

      for (final seq in [slist, slist.reversed]) {
        template = environment.fromString('''{% for item in seq -%}
            {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
                loop.revindex0 }}|{{ loop.first }}|{{ loop.last }}|{{
               loop.length }}###{% endfor %}''');

        final parts = template.render({'seq': seq}).split('###');
        final one = parts[0].split('|');
        final two = parts[1].split('|');

        expect(one[0], equals('1'));
        expect(one[1], equals('0'));
        expect(one[2], equals('2'));
        expect(one[3], equals('1'));
        expect(one[4], equals('true'));
        expect(one[5], equals('false'));
        expect(one[6], equals('2'));

        expect(two[0], equals('2'));
        expect(two[1], equals('1'));
        expect(two[2], equals('1'));
        expect(two[3], equals('0'));
        expect(two[4], equals('false'));
        expect(two[5], equals('true'));
        expect(two[6], equals('2'));
      }
    });

    test('cycling', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq %}{{ 
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''');
      final seq = range(4);
      final through = ['<1>', '<2>'];
      expect(template.render({'seq': seq, 'through': through}), equals('<1><2>' * 4));
    });

    test('lookaround', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq -%}
            {{ loop.previtem | default('x') }}-{{ item }}-{{
            loop.nextitem | default('x') }}|
        {%- endfor %}''');
      expect(template.render({'seq': range(4)}), equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
    });

    test('changed', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq -%}
            {{ loop.changed(item) }},
        {%- endfor %}''');
      final seq = [null, null, 1, 2, 2, 3, 4, 4, 4];
      expect(template.render({'seq': seq}), equals('true,false,true,true,false,true,true,false,false,'));
    });

    test('scope', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in seq %}{% endfor %}{{ item }}');
      expect(template.render({'seq': range(10)}), equals(''));
    });

    test('varlen', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in iter %}{{ item }}{% endfor %}');

      Iterable<int> inner() sync* {
        for (var i = 0; i < 5; i++) {
          yield i;
        }
      }

      expect(template.render({'iter': inner()}), equals('01234'));
    });

    test('noniter', () {
      final environment = Environment();
      final template = environment.fromString('{% for item in none %}...{% endfor %}');
      expect(() => template.render(), throwsA(isA<TypeError>()));
    });

    test('recursive', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq recursive -%}
            [{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}''');
      final seq = [
        {
          'a': 1,
          'b': [
            {'a': 1},
            {'a': 2}
          ]
        },
        {
          'a': 2,
          'b': [
            {'a': 1},
            {'a': 2}
          ]
        },
        {
          'a': 3,
          'b': [
            {'a': 'a'}
          ]
        },
      ];
      expect(template.render({'seq': seq}), equals('[1<[1][2]>][2<[1][2]>][3<[a]>]'));
    });

    test('recursive lookaround', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq recursive -%}
            [{{ loop.previtem.a if loop.previtem is defined else 'x' }}.{{
            item.a }}.{{ loop.nextitem.a if loop.nextitem is defined else 'x'
            }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}''');
      expect(template.render(recursiveData), equals('[x.1.2<[x.1.2][1.2.x]>][1.2.3<[x.1.2][1.2.x]>][2.3.x<[x.a.x]>]'));
    });

    test('recursive depth0', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq recursive -%}
        [{{ loop.depth0 }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}''');
      expect(template.render(recursiveData), equals('[0:1<[1:1][1:2]>][0:2<[1:1][1:2]>][0:3<[1:a]>]'));
    });

    test('recursive depth', () {
      final environment = Environment();
      final template = environment.fromString('''{% for item in seq recursive -%}
        [{{ loop.depth }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}''');
      expect(template.render(recursiveData), equals('[1:1<[2:1][2:2]>][1:2<[2:1][2:2]>][1:3<[2:a]>]'));
    });

    test('looploop', () {
      final environment = Environment();
      final template = environment.fromString('''{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}''');
      final table = ['ab', 'cd'];
      expect(template.render({'table': table}), equals('[1|1][1|2][2|1][2|2]'));
    });

    test('reversed bug', () {
      final environment = Environment();
      final template = environment.fromString('{% for i in items %}{{ i }}'
          '{% if not loop.last %}'
          ',{% endif %}{% endfor %}');
      final items = [3, 2, 1].reversed;
      expect(template.render({'items': items}), equals('1,2,3'));
    });

    test('loop errors', () {
      final environment = Environment();
      var template = environment.fromString('{% for item in [1] if loop.index == 0 %}...{% endfor %}');
      expect(() => template.render(), throwsA(isA<UndefinedError>()));
      template = environment.fromString('{% for item in [] %}...{% else %}{{ loop }}{% endfor %}');
      expect(template.render(), equals(''));
    });

    test('loop filter', () {
      final environment = Environment();
      var template = environment.fromString('{% for item in range(10) if item '
          'is even %}[{{ item }}]{% endfor %}');
      expect(template.render(), equals('[0][2][4][6][8]'));
      template = environment.fromString('''
            {%- for item in range(10) if item is even %}[{{
                loop.index }}:{{ item }}]{% endfor %}''');
      expect(template.render(), equals('[1:0][2:2][3:4][4:6][5:8]'));
    });

    test('loop unassignable', () {
      final environment = Environment();
      expect(() => environment.fromString('{% for loop in seq %}...{% endfor %}'), throwsA(isA<TemplateSyntaxError>()));
    });

    test('scoped special var', () {
      final environment = Environment();
      final template = environment.fromString('{% for s in seq %}[{{ loop.first }}{% for c in s %}'
          '|{{ loop.first }}{% endfor %}]{% endfor %}');
      final seq = ['ab', 'cd'];
      expect(template.render({'seq': seq}), equals('[true|true|false][false|true|false]'));
    });

    test('scoped loop var', () {
      final environment = Environment();
      var template = environment.fromString('{% for x in seq %}{{ loop.first }}'
          '{% for y in seq %}{% endfor %}{% endfor %}');
      expect(template.render({'seq': 'ab'}), 'truefalse');
      template = environment.fromString('{% for x in seq %}{% for y in seq %}'
          '{{ loop.first }}{% endfor %}{% endfor %}');
      expect(template.render({'seq': 'ab'}), equals('truefalsetruefalse'));
    });

    test('recursive empty loop iter', () {
      final environment = Environment();
      final template = environment.fromString('''
        {%- for item in foo recursive -%}{%- endfor -%}
        ''');
      expect(template.render(), equals(''));
    });

    // TODO: after macro: add tests: call in loop, scoping bug

    test('unpacking', () {
      final environment = Environment();
      final template = environment.fromString('{% for a, b, c in [[1, 2, 3]] %}'
          '{{ a }}|{{ b }}|{{ c }}{% endfor %}');
      expect(template.render(), equals('1|2|3'));
    });

    test('intended scoping with set', () {
      final environment = Environment();
      var template = environment.fromString('{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      final data = {
        'x': 0,
        'seq': [1, 2, 3]
      };
      expect(template.render(data), equals('010203'));
      template = environment.fromString('{% set x = 9 %}{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      expect(template.render(data), equals('919293'));
    });
  });
}
