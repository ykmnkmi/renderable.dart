import 'dart:convert';

import 'package:renderable/jinja.dart';
import 'package:test/test.dart';

void main() {
  group('With', () {
    test('with', () {
      final environment = Environment();
      final template = environment.fromString('''{% with a=42, b=23 -%}
            {{ a }} = {{ b }}
        {% endwith -%}
            {{ a }} = {{ b }}''');

      final lines = LineSplitter().convert(template.render({'a': 1, 'b': 2})).map((line) => line.trim()).toList();
      expect(lines[0], equals('42 = 23'));
      expect(lines[1], equals('1 = 2'));
    });

    test('with argument scoping', () {
      final environment = Environment();
      final template = environment.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}''');
      expect(template.render({'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });
}
