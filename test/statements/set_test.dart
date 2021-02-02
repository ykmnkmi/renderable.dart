// ignore_for_file: inference_failure_on_collection_literal

import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:renderable/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Set', () {
    test('normal', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set foo = 1 %}{{ foo }}');
      expect(template.render(), equals('1'));
    });

    test('block', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set foo %}42{% endset %}{{ foo }}');
      expect(template.render(), equals('42'));
    });

    test('block escaping', () {
      final environment = Environment(autoEscape: true);
      final template = environment.fromString('{% set foo %}<em>{{ test }}</em>{% endset %}foo: {{ foo }}');
      expect(template.render(<String, Object>{'test': '<unsafe>'}), equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('set invalid', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      expect(() => environment.fromString('{% set foo["bar"] = 1 %}'), throwsA(isA<TemplateSyntaxError>()));
      final template = environment.fromString('{% set foo.bar = 1 %}');
      expect(() => template.render(<String, Object>{'foo': <Object, Object>{}}),
          throwsA(predicate((error) => error is TemplateRuntimeError && error.message == 'non-namespace object')));
    });

    test('namespace redefined', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set ns = namespace() %}{% set ns.bar = "hi" %}');
      expect(() => template.render(<String, Object>{'namespace': () => <Object, Object>{}}),
          throwsA(predicate((error) => error is TemplateRuntimeError && error.message == 'non-namespace object')));
    });

    test('namespace', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set ns = namespace() %}{% set ns.bar = "42" %}{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('namespace block', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set ns = namespace() %}{% set ns.bar %}42{% endset %}{{ ns.bar }}');
      expect(template.render(), equals('42'));
    });

    test('init namespace', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set ns = namespace(d, self=37) %}{% set ns.b = 42 %}{{ ns.a }}|{{ ns.self }}|{{ ns.b }}');
      expect(
        template.render(<String, Object>{
          'd': <String, Object>{'a': 13}
        }),
        equals('13|37|42'),
      );
    });

    test('namespace loop', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set ns = namespace(found=false) %}{% for x in range(4) %}{% if x == v %}'
          '{% set ns.found = true %}{% endif %}{% endfor %}{{ ns.found }}');
      expect(template.render(<String, Object>{'v': 3}), equals('true'));
      expect(template.render(<String, Object>{'v': 4}), equals('false'));
    });

    // TODO: namespace macro

    test('block escapeing filtered', () {
      final environment = Environment(autoEscape: true);
      final template = environment.fromString('{% set foo | trim %}<em>{{ test }}</em>    {% endset %}foo: {{ foo }}');
      expect(template.render(<String, Object>{'test': '<unsafe>'}), equals('foo: <em>&lt;unsafe&gt;</em>'));
    });

    test('block filtered', () {
      final environment = Environment(getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set foo | trim | length | string %} 42    {% endset %}{{ foo }}');
      expect(template.render(), equals('2'));
    });

    test('block filtered set', () {
      dynamic myfilter(dynamic value, dynamic arg) {
        assert(arg == ' xxx ');
        return value;
      }

      final environment = Environment(filters: {'myfilter': myfilter}, getField: getField, trimBlocks: true);
      final template = environment.fromString('{% set a = " xxx " %}{% set foo | myfilter(a) | trim | length | string %} '
          '{% set b = " yy " %} 42 {{ a }}{{ b }}   {% endset %}{{ foo }}');
      expect(template.render(), equals('11'));
    });
  });
}
