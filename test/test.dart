// ignore_for_file: avoid_print, invalid_use_of_protected_member

import 'package:renderable/reflection.dart';
import 'package:renderable/src/context.dart';
import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/optimizer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> arguments) {
  final source = '{% for x in seq %}{{ loop.first }}{% for y in seq %}{% endfor %}{% endfor %}';
  // final source = 'hello {{- name -}}!';

  try {
    final environment = Environment();

    print('source:');
    print(source);

    final lexer = Lexer(environment);
    final tokens = lexer.tokenize(source);

    print('\ntokens:');
    tokens.forEach(print);

    final reader = TokenReader(tokens);
    final parser = Parser(environment);
    final nodes = parser.scan(reader);

    print('\nnodes:');
    nodes.forEach(print);

    optimizer.visitAll(nodes, Context(environment));

    print('\noptimized nodes:');
    nodes.forEach(print);

    print('\nrender:');
    final template = Template.parsed(environment, nodes);
    final render = RenderWrapper.wrap(template.render);
    print(render(seq: 'ab'));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
