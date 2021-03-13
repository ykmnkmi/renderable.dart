// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString('''{% for item in seq recursive -%}
            [{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}''');
    final seq = [
      {
        'a': 1,
        'b': [
          {'a': 1},
          {'a': 2},
        ]
      },
      // {
      //   'a': 2,
      //   'b': [
      //     {'a': 1},
      //     {'a': 2}
      //   ]
      // },
      // {
      //   'a': 3,
      //   'b': [
      //     {'a': 'a'}
      //   ]
      // },
    ];
    print(template.render({'seq': seq}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
