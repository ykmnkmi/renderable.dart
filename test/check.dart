// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment(autoEscape: true);
    final template = environment.fromString('{{ ["<foo>", "<span>foo</span>" | safe] | join }}');
    print('&lt;foo&gt;<span>foo</span>');
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
