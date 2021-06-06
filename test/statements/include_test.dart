import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Include', () {
    late Environment environment;

    setUpAll(() {
      environment = Environment(
        loader: MapLoader({
          'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
          'header': '[{{ foo }}|{{ 23 }}]',
          'o_printer': '({{ o }})',
        }),
        globals: {'bar': 23},
      );
    });

    test('context include', () {
      var template = environment.fromString('{% include "header" %}');
      expect(template.render({'foo': 42}), equals('[42|23]'));
      template = environment.fromString('{% include "header" with context %}');
      expect(template.render({'foo': 42}), equals('[42|23]'));
      template = environment.fromString('{% include "header" without context %}');
      expect(template.render({'foo': 42}), equals('[|23]'));
    });

    test('include ignoring missing', () {
      var template = environment.fromString('{% include "missing" %}');
      expect(() => template.render(), throwsA(isA<TemplateNotFound>()));

      for (final scope in ['', 'with context', 'without context']) {
        template = environment.fromString('{% include "missing" ignore missing $scope %}');
        expect(template.render(), equals(''));
      }
    });

    test('context include with overrides', () {
      var environment = Environment(
        loader: MapLoader({
          'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}',
          'item': '{{ item }}',
        }),
      );

      expect(environment.getTemplate('main').render(), equals('123'));
    });

    // TODO: after macro: add tests: unoptimized_scopes, import_from_with_context
  });
}
