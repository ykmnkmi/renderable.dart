// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    print(environment.fromString('{% autoescape false %}Autoescaping is inactive within this block{% endautoescape %}').render());
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
