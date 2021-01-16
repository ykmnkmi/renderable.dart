// ignore_for_file: inference_failure_on_collection_literal

import 'dart:convert';

import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('With', () {
    final environment = Environment();

    test('with', () {
      final template = environment.fromString('''{% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''');
      final lines = [for (final line in const LineSplitter().convert(template.render({'a': 1, 'b': 2}))) line.trim()];
      expect(lines, containsAllInOrder(['42 = 23', '1 = 2']));
    });

    test('with argument scoping', () {
      final template = environment.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}''');
      expect(template.render({'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });
}
