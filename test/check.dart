// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString('{% for item in [1, 2, 3] %}{{ item }}{% endfor %}');
    print(template.nodes);
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
