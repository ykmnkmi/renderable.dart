// ignore_for_file: inference_failure_on_collection_literal

import 'dart:collection';

import 'package:renderable/jinja.dart';
import 'package:renderable/runtime.dart';
import 'package:test/test.dart';

class MyMap<K, V> extends MapBase<K, V> {
  @override
  Iterable<K> get keys {
    throw UnimplementedError();
  }

  @override
  V? operator [](Object? key) {
    throw UnimplementedError();
  }

  @override
  void operator []=(K key, V value) {
    throw UnimplementedError();
  }

  @override
  void clear() {
    throw UnimplementedError();
  }

  @override
  V? remove(Object? key) {
    throw UnimplementedError();
  }
}

void main() {
  group('Test', () {
    test('defined', () {
      final environment = Environment();
      final template = environment.fromString('{{ missing is defined }}|{{ true is defined }}');
      expect(template.render(), equals('false|true'));
    });

    test('even', () {
      final environment = Environment();
      final template = environment.fromString('{{ 1 is even }}|{{ 2 is even }}');
      expect(template.render(), equals('false|true'));
    });

    test('odd', () {
      final environment = Environment();
      final template = environment.fromString('{{ 1 is odd }}|{{ 2 is odd }}');
      expect(template.render(), equals('true|false'));
    });

    test('lower', () {
      final environment = Environment();
      final template = environment.fromString('{{ "foo" is lower }}|{{ "FOO" is lower }}');
      expect(template.render(), equals('true|false'));
    });

    test('types', () {
      final environment = Environment();

      final matches = {
        'none is none': true,
        'false is none': false,
        'true is none': false,
        '42 is none': false,
        'none is true': false,
        'false is true': false,
        'true is true': true,
        '0 is true': false,
        '1 is true': false,
        '42 is true': false,
        'none is false': false,
        'false is false': true,
        'true is false': false,
        '0 is false': false,
        '1 is false': false,
        '42 is false': false,
        'none is boolean': false,
        'false is boolean': true,
        'true is boolean': true,
        '0 is boolean': false,
        '1 is boolean': false,
        '42 is boolean': false,
        '0.0 is boolean': false,
        '1.0 is boolean': false,
        '3.14159 is boolean': false,
        'none is integer': false,
        'false is integer': false,
        'true is integer': false,
        '42 is integer': true,
        '3.14159 is integer': false,
        '(10 ** 100) is integer': true,
        'none is float': false,
        'false is float': false,
        'true is float': false,
        '42 is float': false,
        '4.2 is float': true,
        '(10 ** 100) is float': false,
        'none is number': false,
        // difference: false is not num
        'false is number': false,
        // difference: true is not num
        'true is number': false,
        '42 is number': true,
        '3.14159 is number': true,
        // not supported: complex
        // 'complex is number': true,
        '(10 ** 100) is number': true,
        'none is string': false,
        'false is string': false,
        'true is string': false,
        '42 is string': false,
        '"foo" is string': true,
        'none is sequence': false,
        'false is sequence': false,
        '42 is sequence': false,
        '"foo" is sequence': true,
        '[] is sequence': true,
        '[1, 2, 3] is sequence': true,
        '{} is sequence': true,
        'none is mapping': false,
        'false is mapping': false,
        '42 is mapping': false,
        '"foo" is mapping': false,
        '[] is mapping': false,
        '{} is mapping': true,
        'mydict is mapping': true,
        'none is iterable': false,
        'false is iterable': false,
        '42 is iterable': false,
        // difference: string is not iterable
        '"foo" is iterable': false,
        '[] is iterable': true,
        // difference: map is not iterable
        '{} is iterable': false,
        'range(5) is iterable': true,
        'none is callable': false,
        'false is callable': false,
        '42 is callable': false,
        '"foo" is callable': false,
        '[] is callable': false,
        '{} is callable': false,
        'range is callable': true,
      };

      matches.forEach((op, expekt) {
        final template = environment.fromString('{{ $op }}');
        expect(template.render({'mydict': MyMap<dynamic, dynamic>()}), equals('$expekt'));
      });
    });

    test('upper', () {
      final environment = Environment();
      final template = environment.fromString('{{ "FOO" is upper }}|{{ "foo" is upper }}');
      expect(template.render(), equals('true|false'));
    });

    test('equal to', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo is eq 12 }}|'
          '{{ foo is eq 0 }}|'
          '{{ foo is eq (3 * 4) }}|'
          '{{ bar is eq "baz" }}|'
          '{{ bar is eq "zab" }}|'
          '{{ bar is eq ("ba" + "z") }}|'
          '{{ bar is eq bar }}|'
          '{{ bar is eq foo }}');
      expect(template.render({'foo': 12, 'bar': 'baz'}), equals('true|false|true|true|false|true|true|false'));
    });

    test('compare aliases', () {
      final environment = Environment();
      final matches = {
        'eq 2': true,
        'eq 3': false,
        'ne 3': true,
        'ne 2': false,
        'lt 3': true,
        'lt 2': false,
        'le 2': true,
        'le 1': false,
        'gt 1': true,
        'gt 2': false,
        'ge 2': true,
        'ge 3': false,
      };

      matches.forEach((op, expekt) {
        final template = environment.fromString('{{ 2 is $op }}');
        expect(template.render(), equals('$expekt'));
      });
    });

    test('same as', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo is sameas false }}|{{ 0 is sameas false }}');
      expect(template.render({'foo': false}), equals('true|false'));
    });

    test('no paren for arg 1', () {
      final environment = Environment();
      final template = environment.fromString('{{ foo is sameas none }}');
      expect(template.render({'foo': null}), equals('true'));
    });

    test('escaped', () {
      final environment = Environment();
      final template = environment.fromString('{{  x is escaped }}|{{ y is escaped  }}');
      expect(template.render({'x': 'foo', 'y': Markup('foo')}), equals('false|true'));
    });

    test('greater than', () {
      final environment = Environment();
      final template = environment.fromString('{{ 1 is greaterthan 0 }}|{{ 0 is greaterthan 1 }}');
      expect(template.render(), equals('true|false'));
    });

    test('less than', () {
      final environment = Environment();
      final template = environment.fromString('{{ 0 is lessthan 1 }}|{{ 1 is lessthan 0 }}');
      expect(template.render(), equals('true|false'));
    });

    test('multiple test', () {
      final items = <dynamic>[];

      bool matching(dynamic x, dynamic y) {
        items.add(<dynamic>[x, y]);
        return false;
      }

      final environment = Environment(tests: {'matching': matching});
      final template = environment.fromString(
          '{{ "us-west-1" is matching "(us-east-1|ap-northeast-1)" or "stage" is matching "(dev|stage)" }}');
      expect(template.render(), equals('false'));
      expect(items[0], equals(['us-west-1', '(us-east-1|ap-northeast-1)']));
      expect(items[1], equals(['stage', '(dev|stage)']));
    });

    test('in', () {
      final environment = Environment();
      final template = environment.fromString('{{ "o" is in "foo" }}|'
          '{{ "foo" is in "foo" }}|'
          '{{ "b" is in "foo" }}|'
          '{{ 1 is in ((1, 2)) }}|'
          '{{ 3 is in ((1, 2)) }}|'
          '{{ 1 is in [1, 2] }}|'
          '{{ 3 is in [1, 2] }}|'
          '{{ "foo" is in {"foo": 1} }}|'
          '{{ "baz" is in {"bar": 1} }}');
      expect(template.render(), equals('true|true|false|true|false|true|false|true|false'));
    });
  });
}
