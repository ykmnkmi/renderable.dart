// ignore_for_file: inference_failure_on_collection_literal

import 'dart:convert';

import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';
import 'package:test/test.dart';

void main() {
  group('With', () {
    test('with', () {
      final environment = Environment();
      final template = environment.fromString('''{% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''');
      final lines = [for (final line in const LineSplitter().convert(render(template, a: 1, b: 2) as String)) line.trim()];
      expect(lines, containsAllInOrder(['42 = 23', '1 = 2']));
    });

    test('with argument scoping', () {
      final environment = Environment();
      final template = environment.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}''');
      expect(render(template, b: 3, e: 4), equals('1|2|3|4|5'));
    });
  });
}
