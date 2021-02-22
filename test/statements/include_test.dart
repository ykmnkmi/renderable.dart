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
    });
  });
}
