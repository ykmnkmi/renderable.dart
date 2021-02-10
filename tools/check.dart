// ignore_for_file: avoid_print

import 'package:renderable/src/textwrap.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final text = "Hello there, how are you this fine day?  I'm glad to hear it!";
    print(TextWrapper(width: 12).wrap(text));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
