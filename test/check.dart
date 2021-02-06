// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment();
    final template = environment.fromString('{{ foo() }}');
    print(template.nodes);
    print(template.render(<String, Object>{'foo': Foo()}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}

class Foo {
  String call() {
    return 'FOO';
  }
}