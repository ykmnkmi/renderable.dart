import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      final environment = Environment(getField: getField);
      final template = environment.fromString('{{ foo["items"] }}');
      expect(render(template, foo: {'items': 42}), equals('42'));
    });

    test('finalize', () {
      final environment = Environment(finalize: (obj) => obj ?? '');
      final template = environment.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      expect(render(template, seq: [null, 1, 'foo']), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final environment = Environment(finalize: (obj) => obj ?? '');
      final template = environment.fromString('<{{ none }}>');
      expect(template.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final environment = Environment(finalize: (obj) => obj.runtimeType);
      final template = environment.fromString('<{{ value }}>');
      // if template data was finalized, it would print 'StringintString'.
      expect(render(template, value: 123), equals('<int>'));
    });

    test('context finalize', () {
      dynamic finalize(Context context, dynamic value) {
        return value * context['scale'];
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(render(template, value: 5, scale: 3), equals('15'));
    });

    test('env autoescape', () {
      dynamic finalize(Environment environment, dynamic value) {
        return '${environment.variableBegin} ${represent(value)} ${environment.variableEnd}';
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(render(template, value: 'hello'), equals("{{ 'hello' }}"));
    });
  });
}
