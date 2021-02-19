// ignore_for_file: avoid_print

import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final string = 'asd bfd erwr';
    final pattern = RegExp(r'\w+');
    print(pattern.allMatches(string).length);
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
