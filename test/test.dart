import 'package:renderable/src/enirvonment.dart';
import 'package:renderable/src/lexer.dart';
import 'package:renderable/src/parser.dart';
import 'package:renderable/src/reader.dart';
import 'package:stack_trace/stack_trace.dart';

void main(List<String> args) {
  try {
    final source = '{% if a == 0 %}0' + List<String>.generate(1, (int i) => '{% elif a == ${i + 1} %}${i + 1}').join() + '{% else %}x{% endif %}';
    print(source);
    final environment = Environment();
    final lexer = Lexer(environment);
    final tokens = lexer.tokenize(source);
    tokens.forEach(print);
    final reader = TokenReader(tokens);
    final parser = Parser(environment);
    final nodes = parser.scan(reader);
    nodes.forEach(print);
    final template = Template.parsed(environment, nodes);
    print(template.render({'2': 0}));
  } catch (error, trace) {
    print(error);
    print(Trace.from(trace));
  }
}
