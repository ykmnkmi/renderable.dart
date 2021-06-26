import 'package:test/test.dart';

import '../environment.dart';

void main() {
  group('If', () {
    test('simple', () {
      final tmpl = env.fromString('{% if true %}...{% endif %}');
      expect(tmpl.render(), equals('...'));
    });

    test('elif', () {
      final tmpl = env.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(tmpl.render(), equals('...'));
    });

    test('elif deep', () {
      final eilfs = <String>[
        for (var i = 0; i < 999; i++) '{% elif a == ${i + 1} %}${i + 1}'
      ].join('\n');
      final tmpl =
          env.fromString('{% if a == 0 %}0$eilfs{% else %}x{% endif %}');
      expect(tmpl.render({'a': 0}), equals('0'));
      expect(tmpl.render({'a': 10}), equals('10'));
      expect(tmpl.render({'a': 999}), equals('999'));
      expect(tmpl.render({'a': 1000}), equals('x'));
    });

    test('else', () {
      final tmpl = env.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(tmpl.render(), equals('...'));
    });

    test('empty', () {
      final tmpl = env.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(tmpl.render(), equals('[]'));
    });

    test('complete', () {
      final tmpl = env.fromString(
          '{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}');
      expect(
          tmpl.render({'a': 0, 'b': false, 'c': 42, 'd': 42.0}), equals('C'));
    });

    test('no scope', () {
      var tmpl =
          env.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.render({'a': true}), equals('1'));
      tmpl =
          env.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(tmpl.render(), equals('1'));
    });
  });
}
