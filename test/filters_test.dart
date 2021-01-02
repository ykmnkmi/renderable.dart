import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/src/markup.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

class User {
  User(this.name);

  final String name;
}

void main() {
  group('Filters', () {
    final environment = Environment();

    test('attr', () {
      final environment = Environment(getField: getField);
      final template = environment.fromString('{{ user | attr("name") }}');
      final user = User('jane');
      expect(template.render({'user': user}), equals('jane'));
    });

    test('batch', () {
      final template = environment.fromString('{{ foo | batch(3) | list }}|{{ foo | batch(3, "X") | list }}');
      expect(template.render({'foo': range(10)}),
          equals('[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9]]|[[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, X, X]]'));
    });

    test('capitalize', () {
      final template = environment.fromString('{{ "foo bar" | capitalize }}');
      expect(template.render(), equals('Foo bar'));
    });

    test('center', () {
      final template = environment.fromString('{{ "foo" | center(9) }}');
      expect(template.render(), equals('   foo   '));
    });

    test('chaining', () {
      final template = environment.fromString('{{ ["<foo>", "<bar>"]| first | upper | escape }}');
      expect(template.render(), equals('&lt;FOO&gt;'));
    });

    test('default', () {
      final template = environment.fromString(
          '{{ missing | default("no") }}|{{ false | default("no") }}|{{ false | default("no", true) }}|{{ given | default("no") }}');
      expect(template.render({'given': 'yes'}), equals('no|false|no|yes'));
    });

    test('escape', () {
      final template = environment.fromString('{{ \'<">&\' | escape }}');
      expect(template.render(), equals('&lt;&#34;&gt;&amp;'));
    });

    test('filesizeformat', () {
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
      expect(template.render(),
          equals('100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB'));
    });

    test('first', () {
      final template = environment.fromString('{{ foo | first }}');
      expect(template.render({'foo': range(10)}), equals('0'));
    });

    test('force escape', () {
      final template = environment.fromString('{{ x | forceescape }}');
      expect(template.render({'x': Markup('<div />')}), equals('&lt;div /&gt;'));
    });

    test('join', () {
      final template = environment.fromString('{{ [1, 2, 3] | join("|") }}');
      expect(template.render(), equals('1|2|3'));
    });

    test('join attribute', () {
      final template = environment.fromString('{{ users | join(", ", "username") }}');
      final users = ['foo', 'bar'].map((name) => {'username': name});
      expect(template.render({'users': users}), equals('foo, bar'));
    });

    test('last', () {
      final template = environment.fromString('''{{ foo | last }}''');
      expect(template.render({'foo': range(10)}), equals('9'));
    });

    test('length', () {
      final template = environment.fromString('{{ "hello world"|length }}');
      expect(template.render(), equals('11'));
    });

    test('lower', () {
      final template = environment.fromString('''{{ "FOO" | lower }}''');
      expect(template.render(), equals('foo'));
    });

    test('upper', () {
      final template = environment.fromString('{{ "foo" | upper }}');
      expect(template.render(), equals('FOO'));
    });
  });
}
