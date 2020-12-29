import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/optimizer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  final source = 'hello {{ "wor" + "ld" }}!';

  try {
    final environment = Environment();

    print('source:');
    print(source);

    final lexer = Lexer(environment);
    final tokens = lexer.tokenize(source);

    print('tokens:');
    tokens.forEach(print);

    final reader = TokenReader(tokens);
    final parser = Parser(environment);
    final nodes = parser.scan(reader);

    print('nodes:');
    nodes.forEach(print);

    final optimizer = Optimizer();
    optimizer.visitAll(nodes);

    print('optimized nodes:');
    nodes.forEach(print);

    final template = Template.parsed(environment, nodes);
    print(template.render());
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
