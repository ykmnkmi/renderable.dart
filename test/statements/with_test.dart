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

      final lines = <String>[
        for (final line in const LineSplitter().convert(template.render(<String, Object>{'a': 1, 'b': 2}))) line.trim()
      ];

      expect(lines, containsAllInOrder(<String>['42 = 23', '1 = 2']));
    });

    test('with argument scoping', () {
      final environment = Environment();
      final template = environment.fromString('''
        {%- with a=1, b=2, c=b, d=e, e=5 -%}
            {{ a }}|{{ b }}|{{ c }}|{{ d }}|{{ e }}
        {%- endwith -%}''');
      expect(template.render(<String, Object>{'b': 3, 'e': 4}), equals('1|2|3|4|5'));
    });
  });
}
