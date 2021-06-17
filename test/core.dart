import 'package:test/expect.dart' as expect;

export 'package:test/scaffolding.dart' show group, setUpAll, test;

extension ExpectExtension on Object? {
  void equals(Object? value) {
    expect.expect(this, expect.equals(value));
  }
}
