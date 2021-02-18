// ignore_for_file: avoid_print

import 'package:stack_trace/stack_trace.dart';

void main() {
  try {} catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
