import 'package:renderable/jinja.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('For', () {
    final environment = Environment();

    test('simple', () {
      final template = environment.fromString('{% for item in seq %}{{ item }}{% endfor %}');
      expect(template.render({'seq': range(10)}), equals('0123456789'));
    });

    test('else', () {
      final template = environment.fromString('{% for item in seq %}XXX{% else %}...{% endfor %}');
      expect(template.render(), equals('...'));
    });

    test('else scoping item', () {
      final template = environment.fromString('{% for item in [] %}{% else %}{{ item }}{% endfor %}');
      expect(template.render({'item': 42}), equals('42'));
    });

    test('empty blocks', () {
      final template = environment.fromString('<{% for item in seq %}{% else %}{% endfor %}>');
      expect(template.render(), equals('<>'));
    });

    test('context vars', () {
      final slist = <int>[42, 24];
      Template template;

      for (final seq in <Iterable<int>>[slist, slist.reversed]) {
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
      final template = environment.fromString('''{% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(*through) }}{% endfor %}''');
      expect(template.render({'seq': range(4), 'through': <String>['<1>', '<2>']}), equals('<1><2>' * 4));
    });

    test('lookaround', () {
      final template = environment.fromString('''{% for item in seq -%}
            {{ loop.previtem | default('x') }}-{{ item }}-{{
            loop.nextitem | default('x') }}|
        {%- endfor %}''');
      expect(template.render({'seq': range(4)}), equals('x-0-1|0-1-2|1-2-3|2-3-x|'));
    });

    test('changed', () {
      final template = environment.fromString('''{% for item in seq -%}
            {{ loop.changed(item) }},
        {%- endfor %}''');
      expect(
          template.render({'seq': <int?>[null, null, 1, 2, 2, 3, 4, 4, 4]}),
          equals('true,false,true,true,false,true,true,false,false,'));
    });

    test('scope', () {
      final template = environment.fromString('{% for item in seq %}{% endfor %}{{ item }}');
      expect(template.render({'seq': range(10)}), equals(''));
    });

    test('varlen', () {
      final template = environment.fromString('{% for item in iter %}{{ item }}{% endfor %}');

      Iterable<int> inner() sync* {
        for (var i = 0; i < 5; i++) {
          yield i;
        }
      }

      expect(template.render({'iter': inner()}), equals('01234'));
    });

    test('noniter', () {
      final template = environment.fromString('{% for item in none %}...{% endfor %}');
      expect(() => template.render(), throwsArgumentError);
    });

    // TODO: add test: recursive
    // TODO: add test: recursive lookaround
    // TODO: add test: recursive depth0
    // TODO: add test: recursive depth

    test('looploop', () {
      final template = environment.fromString('''{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}''');
      expect(template.render({'table': <String>['ab', 'cd']}), equals('[1|1][1|2][2|1][2|2]'));
    });

    test('reversed bug', () {
      final template = environment.fromString('{% for i in items %}{{ i }}'
          '{% if not loop.last %}'
          ',{% endif %}{% endfor %}');
      expect(template.render({'items': <int>[3, 2, 1].reversed}), equals('1,2,3'));
    });

    // TODO: check Error
    // test('loop errors', () {
    //   final template = environment.fromString('''{% for item in [1] if loop.index
    //                                   == 0 %}...{% endfor %}''');
    //   expect(() => template.render(), throwsA(isA<UndefinedError>()));
    // });

    test('loop filter', () {
      var template = environment.fromString('{% for item in range(10) if item '
          'is even %}[{{ item }}]{% endfor %}');
      expect(template.render(), equals('[0][2][4][6][8]'));
      template = environment.fromString('''
            {%- for item in range(10) if item is even %}[{{
                loop.index }}:{{ item }}]{% endfor %}''');
      expect(template.render(), equals('[1:0][2:2][3:4][4:6][5:8]'));
    });

    // TODO: add test: loop unassignable

    test('scoped special var', () {
      final template = environment.fromString('{% for s in seq %}[{{ loop.first }}{% for c in s %}'
          '|{{ loop.first }}{% endfor %}]{% endfor %}');
      expect(template.render({'seq': ['ab', 'cd']}), equals('[true|true|false][false|true|false]'));
    });

    test('scoped loop var', () {
      var template = environment.fromString('{% for x in seq %}{{ loop.first }}'
          '{% for y in seq %}{% endfor %}{% endfor %}');
      final data = {'seq': 'ab'};

      expect(template.render(data), 'truefalse');
      template = environment.fromString('{% for x in seq %}{% for y in seq %}'
          '{{ loop.first }}{% endfor %}{% endfor %}');
      expect(template.render(data), equals('truefalsetruefalse'));
    });

    // TODO: add test: recursive empty loop iter
    // TODO: add test: call in loop
    // TODO: add test: scoping bug

    test('unpacking', () {
      final template = environment.fromString('{% for a, b, c in [[1, 2, 3]] %}'
          '{{ a }}|{{ b }}|{{ c }}{% endfor %}');
      expect(template.render(), equals('1|2|3'));
    });

    test('intended scoping with set', () {
      final data = {'x': 0, 'seq': <int>[1, 2, 3]};
      var template = environment.fromString('{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');

      expect(template.render(data), equals('010203'));
      template = environment.fromString('{% set x = 9 %}{% for item in seq %}{{ x }}'
          '{% set x = item %}{{ x }}{% endfor %}');
      expect(template.render(data), equals('919293'));
    });
  });
}