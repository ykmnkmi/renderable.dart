// ignore_for_file: avoid_print

import 'package:renderable/src/textwrap.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final text = 'Look, goof-ball -- use the -b option!';
    final wrapper = TextWrapper(breakOnHyphens: false);
    print(wrapper.wrap(text));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
