import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('If', () {
    test('simple', () {
      final environment = Environment();
      final template = environment.fromString('{% if true %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('elif', () {
      final environment = Environment();
      final template = environment.fromString('''{% if false %}XXX{% elif true
            %}...{% else %}XXX{% endif %}''');
      expect(template.render(), equals('...'));
    });

    test('elif deep', () {
      final source = '{% if a == 0 %}0' +
          List.generate(999, (int i) => '{% elif a == ${i + 1} %}${i + 1}').join() +
          '{% else %}x{% endif %}';
      final environment = Environment();
      final template = environment.fromString(source);
      expect(template.render({'a': 0}), equals('0'));
      expect(template.render({'a': 10}), equals('10'));
      expect(template.render({'a': 999}), equals('999'));
      expect(template.render({'a': 1000}), equals('x'));
    });

    test('else', () {
      final environment = Environment();
      final template = environment.fromString('{% if false %}XXX{% else %}...{% endif %}');
      expect(template.render(), equals('...'));
    });

    test('empty', () {
      final environment = Environment();
      final template = environment.fromString('[{% if true %}{% else %}{% endif %}]');
      expect(template.render(), equals('[]'));
    });

    test('complete', () {
      final environment = Environment();
      final template = environment.fromString('{% if a %}A{% elif b %}B{% elif c == d %}C{% else %}D{% endif %}');
      expect(template.render({'a': 0, 'b': false, 'c': 42, 'd': 42.0}), equals('C'));
    });

    test('no scope', () {
      final environment = Environment();
      var template = environment.fromString('{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render({'a': true}), equals('1'));
      template = environment.fromString('{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}');
      expect(template.render(), equals('1'));
    });
  });
}
