// ignore_for_file: avoid_print, invalid_use_of_protected_member

import 'package:renderable/src/context.dart';
import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/optimizer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> arguments) {
  final source = '{% set foo %}<em>{{ test }}</em>{% endset %}foo: {{ foo }}';

  try {
    final environment = Environment(autoEscape: true);

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

    final template = Template.parsed(environment, nodes);
    // print('\ntemplate nodes:');
    // nodes.forEach(print);

    print('\nrender:');
    print(template.render({'test': '<unsafe>'}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
