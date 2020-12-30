import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/evaluator.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/optimizer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  final source = '{% if a == 0 %}0' + List<String>.generate(999, (int i) => '{% elif a == ${i + 1} %}${i + 1}').join() + '{% else %}x{% endif %}';

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

    // final optimizer = Optimizer(Evaluator());
    // optimizer.visitAll(nodes);

    print('optimized nodes:');
    nodes.forEach(print);

    final template = Template.parsed(environment, nodes);
    print(template.render({'a': 2}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
