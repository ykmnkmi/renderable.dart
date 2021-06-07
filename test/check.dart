// ignore_for_file: avoid_print

import 'dart:io';

import 'package:renderable/jinja.dart';
import 'package:stack_trace/stack_trace.dart';

void main() {
  final uri = Platform.script.resolve('.');
  final source = '{% extends "layouts/base.html" %}{% block title %}hello {{ name }}!{% endblock %}';

  try {
    final environment = Environment(loader: FileSystemLoader(path: uri.path));
    final template = environment.fromString(source);
    print(template.render({'name': 'jhon'}));
  } catch (error, trace) {
    print(error);
    print(Trace.format(trace));
  }
}
