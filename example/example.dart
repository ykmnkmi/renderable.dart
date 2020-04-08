import 'dart:io';

import 'package:renderable/renderable.dart';

void main(List<String> arguments) {
  final Map<String, Object> context = <String, Object>{'name': 'jhon'};
  final Template template = Template('hello {{ name }}');
  stdout.writeln(template.render(context));
}
