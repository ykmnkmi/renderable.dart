library visitor;

import 'ast.dart';
import 'environment.dart';

class Renderer<C> implements Visitor<C, Object> {
  final Environment environment;

  Renderer(this.environment);

  @override
  String toString() {
    return 'Renderer<$C>()';
  }

  @override
  String visitAll(Iterable<Node> nodes, [C context]) {
    /* TODO: profile join */
    return nodes.map((node) => node.accept<C, Object>(this, context)).join();
  }

  @override
  String visitText(Text text, [C context]) {
    return text.text;
  }

  @override
  Object visitVariable(Variable variable, [C context]) {
    // TODO: стойт ли использовать отдельный класс для рендера словаря?
    Object value;

    if (context is Map<String, Object>) {
      value = context[variable.name];
    } else {
      value = environment.getField(variable.name, context);
    }

    return environment.finalize(value);
  }
}

abstract class Visitor<C, R> {
  R visitAll(Iterable<Node> nodes, [C context]);

  R visitText(Text text, [C context]);

  R visitVariable(Variable variable, [C context]);
}
