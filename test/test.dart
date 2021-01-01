import 'package:renderable/src/context.dart';
import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/optimizer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  final source = 'hello {{ "hello"[1:3] }}!';

  try {
    final environment = Environment();

    print('source:');
    print(source);

    final lexer = Lexer(environment);
    final tokens = lexer.tokenize(source);

    // print('\ntokens:');
    // tokens.forEach(print);

    final reader = TokenReader(tokens);
    final parser = Parser(environment);
    final nodes = parser.scan(reader);

    print('\nnodes:');
    nodes.forEach(print);

    const Optimizer().visitAll(nodes, Context(environment));

    print('\noptimized nodes:');
    nodes.forEach(print);

    print('\nrender:');
    final template = Template.parsed(environment, nodes);
    print(template.render({'one': 1, 'two': 2, 'three': '三'}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
