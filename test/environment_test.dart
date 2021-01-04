import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:test/test.dart';

void main() {
  group('Environment', () {
    test('item and attribute', () {
      final environment = Environment(getField: getField);
      final template = environment.fromString('{{ foo["items"] }}');
      expect(template.render({'foo': {'items': 42}}), equals('42'));
    });

    test('finalize', () {
      final environment = Environment(finalize: (obj) => obj ?? '');
      final template = environment.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      expect(template.render({'seq': [null, 1, 'foo']}), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final environment = Environment(finalize: (obj) => obj ?? '');
      final template = environment.fromString('<{{ none }}>');
      expect(template.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final environment = Environment(finalize: (obj) => obj.runtimeType);
      final template = environment.fromString('<{{ value }}>');
      expect(template.render({'value': 123}), equals('<int>'));
    });
  });
}
