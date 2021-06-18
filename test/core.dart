import 'package:renderable/jinja.dart';
import 'package:test/expect.dart' as expect show expect, equals, orderedEquals;
import 'package:test/expect.dart' show isA, predicate, throwsA;

export 'package:test/scaffolding.dart' show group, setUpAll, test;

extension CoreTest on Object? {
  void equals(Object? value) {
    expect.expect(this, expect.equals(value));
  }

  void orderedEquals(Iterable<Object?> values) {
    expect.expect(this, expect.orderedEquals(values));
  }
}

extension TemplateTest on Template {
  Object? renderThrows<T>({Map<String, Object?>? data, bool Function(T value)? matcher}) {
    expect.expect(() => render(data), throwsA(matcher == null ? isA<T>() : predicate<T>(matcher)));
  }
}
