// ignore_for_file: inference_failure_on_collection_literal

import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('With', () {
    final environment = Environment();

    test('normal', () {
      final template = environment.fromString('''{% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''');
      expect(template.render({'a': 1, 'b': 2}), equals('1'));
    });
  });
}
