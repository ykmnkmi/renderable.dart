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
    late final environment = Environment();

    test('defined', () {
      expect(environment.fromString('{{ missing is defined }}|{{ true is defined }}').render(), equals('false|true'));
    });

    test('even', () {
      expect(environment.fromString('{{ 1 is even }}|{{ 2 is even }}').render(), equals('false|true'));
    });

    test('odd', () {
      expect(environment.fromString('{{ 1 is odd }}|{{ 2 is odd }}').render(), equals('true|false'));
    });

    test('lower', () {
      expect(environment.fromString('{{ "foo" is lower }}|{{ "FOO" is lower }}').render(), equals('true|false'));
    });

    test('types', () {
      // environment.fromString('{{ $op }}').render(data).equals('$expekt');
      var data = {'mydict': MyMap<dynamic, dynamic>()};
      expect(environment.fromString('{{ none is none }}').render(), equals('true'));
      expect(environment.fromString('{{ false is none }}').render(), equals('false'));
      expect(environment.fromString('{{ true is none }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is none }}').render(), equals('false'));
      expect(environment.fromString('{{ none is true }}').render(), equals('false'));
      expect(environment.fromString('{{ false is true }}').render(), equals('false'));
      expect(environment.fromString('{{ true is true }}').render(), equals('true'));
      expect(environment.fromString('{{ 0 is true }}').render(), equals('false'));
      expect(environment.fromString('{{ 1 is true }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is true }}').render(), equals('false'));
      expect(environment.fromString('{{ none is false }}').render(), equals('false'));
      expect(environment.fromString('{{ false is false }}').render(), equals('true'));
      expect(environment.fromString('{{ true is false }}').render(), equals('false'));
      expect(environment.fromString('{{ 0 is false }}').render(), equals('false'));
      expect(environment.fromString('{{ 1 is false }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is false }}').render(), equals('false'));
      expect(environment.fromString('{{ none is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ false is boolean }}').render(), equals('true'));
      expect(environment.fromString('{{ true is boolean }}').render(), equals('true'));
      expect(environment.fromString('{{ 0 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ 1 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ 0.0 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ 1.0 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ 3.14159 is boolean }}').render(), equals('false'));
      expect(environment.fromString('{{ none is integer }}').render(), equals('false'));
      expect(environment.fromString('{{ false is integer }}').render(), equals('false'));
      expect(environment.fromString('{{ true is integer }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is integer }}').render(), equals('true'));
      expect(environment.fromString('{{ 3.14159 is integer }}').render(), equals('false'));
      expect(environment.fromString('{{ (10 ** 100) is integer }}').render(), equals('true'));
      expect(environment.fromString('{{ none is float }}').render(), equals('false'));
      expect(environment.fromString('{{ false is float }}').render(), equals('false'));
      expect(environment.fromString('{{ true is float }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is float }}').render(), equals('false'));
      expect(environment.fromString('{{ 4.2 is float }}').render(), equals('true'));
      expect(environment.fromString('{{ (10 ** 100) is float }}').render(), equals('false'));
      expect(environment.fromString('{{ none is number }}').render(), equals('false'));
      // difference: false is not num
      expect(environment.fromString('{{ false is number }}').render(), equals('false'));
      // difference: true is not num
      expect(environment.fromString('{{ true is number }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is number }}').render(), equals('true'));
      expect(environment.fromString('{{ 3.14159 is number }}').render(), equals('true'));
      // not supported: complex
      // expect(environment.fromString('{{ complex is number }}').render(), equals('true'));
      expect(environment.fromString('{{ (10 ** 100) is number }}').render(), equals('true'));
      expect(environment.fromString('{{ none is string }}').render(), equals('false'));
      expect(environment.fromString('{{ false is string }}').render(), equals('false'));
      expect(environment.fromString('{{ true is string }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is string }}').render(), equals('false'));
      expect(environment.fromString('{{ "foo" is string }}').render(), equals('true'));
      expect(environment.fromString('{{ none is sequence }}').render(), equals('false'));
      expect(environment.fromString('{{ false is sequence }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is sequence }}').render(), equals('false'));
      expect(environment.fromString('{{ "foo" is sequence }}').render(), equals('true'));
      expect(environment.fromString('{{ [] is sequence }}').render(), equals('true'));
      expect(environment.fromString('{{ [1, 2, 3] is sequence }}').render(), equals('true'));
      expect(environment.fromString('{{ {} is sequence }}').render(), equals('true'));
      expect(environment.fromString('{{ none is mapping }}').render(), equals('false'));
      expect(environment.fromString('{{ false is mapping }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is mapping }}').render(), equals('false'));
      expect(environment.fromString('{{ "foo" is mapping }}').render(), equals('false'));
      expect(environment.fromString('{{ [] is mapping }}').render(), equals('false'));
      expect(environment.fromString('{{ {} is mapping }}').render(), equals('true'));
      expect(environment.fromString('{{ mydict is mapping }}').render(), equals('true'));
      expect(environment.fromString('{{ none is iterable }}').render(), equals('false'));
      expect(environment.fromString('{{ false is iterable }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is iterable }}').render(), equals('false'));
      // difference: string is not iterable
      expect(environment.fromString('{{ "foo" is iterable }}').render(), equals('false'));
      expect(environment.fromString('{{ [] is iterable }}').render(), equals('true'));
      // difference: map is not iterable
      expect(environment.fromString('{{ {} is iterable }}').render(), equals('false'));
      expect(environment.fromString('{{ range(5) is iterable }}').render(), equals('true'));
      expect(environment.fromString('{{ none is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ false is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ 42 is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ "foo" is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ [] is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ {} is callable }}').render(), equals('false'));
      expect(environment.fromString('{{ range is callable }}').render(), equals('true'));
    });

    test('upper', () {
      expect(environment.fromString('{{ "FOO" is upper }}|{{ "foo" is upper }}').render(), equals('true|false'));
    });

    test('equal to', () {
      var template = environment.fromString('{{ foo is eq 12 }}|'
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
      expect(environment.fromString('{{ 2 is eq 2 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is eq 3 }}').render(), equals('false'));
      expect(environment.fromString('{{ 2 is ne 3 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is ne 2 }}').render(), equals('false'));
      expect(environment.fromString('{{ 2 is lt 3 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is lt 2 }}').render(), equals('false'));
      expect(environment.fromString('{{ 2 is le 2 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is le 1 }}').render(), equals('false'));
      expect(environment.fromString('{{ 2 is gt 1 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is gt 2 }}').render(), equals('false'));
      expect(environment.fromString('{{ 2 is ge 2 }}').render(), equals('true'));
      expect(environment.fromString('{{ 2 is ge 3 }}').render(), equals('false'));
    });

    test('same as', () {
      var source = '{{ foo is sameas false }}|{{ 0 is sameas false }}';
      expect(environment.fromString(source).render({'foo': false}), equals('true|false'));
    });

    test('no paren for arg 1', () {
      expect(environment.fromString('{{ foo is sameas none }}').render({'foo': null}), equals('true'));
    });

    test('escaped', () {
      var source = '{{  x is escaped }}|{{ y is escaped  }}';
      expect(environment.fromString(source).render({'x': 'foo', 'y': Markup('foo')}), equals('false|true'));
    });

    test('greater than', () {
      var source = '{{ 1 is greaterthan 0 }}|{{ 0 is greaterthan 1 }}';
      expect(environment.fromString(source).render(), equals('true|false'));
    });

    test('less than', () {
      var source = '{{ 0 is lessthan 1 }}|{{ 1 is lessthan 0 }}';
      expect(environment.fromString(source).render(), equals('true|false'));
    });

    test('multiple test', () {
      var items = <Object?>[];

      bool matching(Object? x, Object? y) {
        items.add(<Object?>[x, y]);
        return false;
      }

      var source = '{{ "us-west-1" is matching "(us-east-1|ap-northeast-1)" or "stage" is matching "(dev|stage)" }}';
      var result = Environment(tests: {'matching': matching}).fromString(source).render();
      expect(result, equals('false'));
      expect(items[0], equals(['us-west-1', '(us-east-1|ap-northeast-1)']));
      expect(items[1], equals(['stage', '(dev|stage)']));
    });

    test('in', () {
      var template = environment.fromString('{{ "o" is in "foo" }}|'
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
