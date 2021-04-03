import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('ExtendedAPI', () {
    test('item and attribute', () {
      final environment = Environment(getField: getField);
      final template = environment.fromString('{{ foo["items"] }}');
      final foo = {'items': 42};
      expect(template.render({'foo': foo}), equals('42'));
    });

    test('finalize', () {
      final environment = Environment(finalize: (dynamic obj) => obj ?? '');
      final template = environment.fromString('{% for item in seq %}|{{ item }}{% endfor %}');
      final seq = [null, 1, 'foo'];
      expect(template.render({'seq': seq}), equals('||1|foo'));
    });

    test('finalize constant expression', () {
      final environment = Environment(finalize: (dynamic obj) => obj ?? '');
      final template = environment.fromString('<{{ none }}>');
      expect(template.render(), equals('<>'));
    });

    test('no finalize template data', () {
      final environment = Environment(finalize: (dynamic obj) => obj.runtimeType);
      final template = environment.fromString('<{{ value }}>');
      // if template data was finalized, it would print 'StringintString'.
      expect(template.render({'value': 123}), equals('<int>'));
    });

    test('context finalize', () {
      Object? finalize(Context context, dynamic value) {
        return value * context['scale'];
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(template.render({'value': 5, 'scale': 3}), equals('15'));
    });

    test('env autoescape', () {
      Object? finalize(Environment environment, dynamic value) {
        return '${environment.variableBegin} ${represent(value)} ${environment.variableEnd}';
      }

      final environment = Environment(finalize: finalize);
      final template = environment.fromString('{{ value }}');
      expect(template.render({'value': 'hello'}), equals("{{ 'hello' }}"));
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

    test('template passthrough', () {
      final environment = Environment();
      final template = Template('content');
      expect(environment.getTemplate(template), equals(template));
      expect(environment.selectTemplate([template]), equals(template));
      expect(environment.getOrSelectTemplate([template]), equals(template));
      expect(environment.getOrSelectTemplate(template), equals(template));
    });

    test('get template undefined', () {
      final environment = Environment(loader: MapLoader({}));
      final template = Undefined(name: 'no-name-1');
      expect(() => environment.getTemplate(template), throwsA(isA<UndefinedError>()));
      expect(() => environment.getOrSelectTemplate(template), throwsA(isA<UndefinedError>()));
      expect(() => environment.selectTemplate(template), throwsA(isA<UndefinedError>()));
      expect(() => environment.selectTemplate([template, 'no-name-2']), throwsA(isA<TemplatesNotFound>()));
    });

    // TODO: add test: autoescape autoselect
  });
}
