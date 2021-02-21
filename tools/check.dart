// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final loader = MapLoader({'home.html': '{% include "head.html" %}', 'head.html': 'is head'});
    final environment = Environment(loader: loader);
    print(environment.getTemplate('home.html').render());
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
