import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      final environment = Environment(getField: getField);
      final template = environment.fromString('{{ foo["items"] }}');
      expect(
        template.render(<String, Object>{
          'foo': <String, int>{'items': 42}
        },),
        equals('42'),
      );
    });

    test('finalize', () {
      final environment = Environment(finalize: (dynamic obj) => obj ?? '');
      final template = environment.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      expect(
        template.render(<String, Object>{
          'seq': <Object?>[null, 1, 'foo']
        }),
        equals('||1|foo'),
      );
    });

    test('finalize constant expression', () {
      final environment = Environment(finalize: (Object? obj) => obj ?? '');
      final template = environment.fromString('<{{ none }}>');
      expect(template.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final environment = Environment(finalize: (dynamic obj) => obj.runtimeType);
      final template = environment.fromString('<{{ value }}>');
      // if template data was finalized, it would print 'StringintString'.
      expect(template.render(<String, Object>{'value': 123}), equals('<int>'));
    });

    test('context finalize', () {
      dynamic finalize(Context context, dynamic value) {
        return value * context['scale'];
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(template.render(<String, Object>{'value': 5, 'scale': 3}), equals('15'));
    });

    test('env autoescape', () {
      dynamic finalize(Environment environment, dynamic value) {
        return '${environment.variableBegin} ${represent(value)} ${environment.variableEnd}';
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(template.render(<String, Object>{'value': 'hello'}), equals("{{ 'hello' }}"));
    });

    test('cycler', () {
      final items = [1, 2, 3];
      final cycler = Cycler(items);
      final iterator = cycler.iterator;

      for (final item in items + items) {
        expect(cycler.current, equals(item));
        iterator.moveNext();
        expect(iterator.current, equals(item));
      }

      iterator.moveNext();
      expect(cycler.current, equals(2));
      cycler.reset();
      expect(cycler.current, equals(1));
    });

    // TODO: compileExpression test

    // TODO: getTemplate test

    // TODO: getTemplate test

    // TODO: autoEscapeMatcher test
  });
}
