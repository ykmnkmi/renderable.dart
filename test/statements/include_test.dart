import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('Include', () {
    Environment? environment;

    Environment testEnvironment() {
      return environment ??= Environment(
        loader: MapLoader({
          'module': '{% macro test() %}[{{ foo }}|{{ bar }}]{% endmacro %}',
          'header': '[{{ foo }}|{{ 23 }}]',
          'o_printer': '({{ o }})',
        }),
        globals: {'bar': 23},
      );
    }

    test('context include', () {
      var template = testEnvironment().fromString('{% include "header" %}');
      expect(template.render({'foo': 42}), equals('[42|23]'));
      template = testEnvironment().fromString('{% include "header" with context %}');
      expect(template.render({'foo': 42}), equals('[42|23]'));
      template = testEnvironment().fromString('{% include "header" without context %}');
      expect(template.render({'foo': 42}), equals('[|23]'));
    });

    test('choice includes', () {
      var template = testEnvironment().fromString('{% include ["missing", "header"] %}');
      expect(template.render({'foo': 42}), equals('[42|23]'));
      template = testEnvironment().fromString('{% include ["missing", "missing2"] ignore missing %}');
      expect(template.render({'foo': 42}), equals(''));
      template = testEnvironment().fromString('{% include ["missing", "missing2"] %}');
      expect(() => template.render(), throwsA(isA<TemplatesNotFound>()));

      void testIncludes(Template template, [Map<String, Object?>? context]) {
        context ??= <String, Object?>{};
        context['foo'] = 42;
        expect(template.render(context), equals('[42|23]'));
      }

      template = testEnvironment().fromString('{% include ["missing", "header"] %}');
      testIncludes(template);
      template = testEnvironment().fromString('{% include x %}');
      testIncludes(template, {'x': ['missing', 'header']});
      template = testEnvironment().fromString('{% include [x, "header"] %}');
      testIncludes(template, {'x': 'missing'});
      template = testEnvironment().fromString('{% include x %}');
      testIncludes(template, {'x': 'header'});
      template = testEnvironment().fromString('{% include [x] %}');
      testIncludes(template, {'x': 'header'});
    });

    test('include ignoring missing', () {
      var template = testEnvironment().fromString('{% include "missing" %}');
      expect(() => template.render(), throwsA(isA<TemplateNotFound>()));

      for (final scope in ['', 'with context', 'without context']) {
        template = testEnvironment().fromString('{% include "missing" ignore missing $scope %}');
        expect(template.render(), equals(''));
      }
    });

    test('context include with overrides', () {
      final environment = Environment(loader: MapLoader({'main': '{% for item in [1, 2, 3] %}{% include "item" %}{% endfor %}', 'item': '{{ item }}'}));
      expect(environment.getTemplate('main').render(), equals('123'));
    });

    // TODO: after macro: add tests: unoptimized_scopes, import_from_with_context
  });
}
