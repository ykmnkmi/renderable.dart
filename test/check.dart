// ignore_for_file: avoid_print

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  try {
    final environment = Environment(
      loader: MapLoader(<String, String>{
        'a': '{% block intro %}INTRO{% endblock %}|BEFORE|{% block data %}INNER{% endblock %}|AFTER',
        'b': '{% extends "a" %}{% block data %}({{ super() }}){% endblock %}',
        'c': '{% extends "b" %}{% block intro %}--{{ super() }}--{% endblock %}\n'
            '{% block data %}[{{ super() }}]{% endblock %}',
      }),
    );

    final template = environment.getTemplate('c');
    // '--INTRO--|BEFORE|[(INNER)]|AFTER'
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
