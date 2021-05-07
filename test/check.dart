// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString('{% block hello %}hello {{ name }}{% endblock %}');
    print(template.render({'name': 'jhon'}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
