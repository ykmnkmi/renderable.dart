library visitor;

import 'ast.dart';
import 'environment.dart';
import 'util.dart';

class Renderer<C> implements Visitor<C, String> {
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
  String visitIf(IfStatement ifStatement, [C context]) {
    final pairs = ifStatement.pairs;

    for (final pair in pairs.entries) {
      if (toBool(pair.key.accept(this, context))) {
        return visitAll(pair.value);
      }
    }

    final orElse = ifStatement.orElse;

    if (orElse != null && orElse.isNotEmpty) {
      return visitAll(orElse);
    }
  }

  @override
  String visitText(Text text, [C context]) {
    return text.text;
  }

  @override
  String visitVariable(Variable variable, [C context]) {
    // TODO: стойт ли использовать отдельный класс для рендера словаря?
    Object value;

    if (context is Map<String, Object>) {
      value = context[variable.name];
    } else {
      value = environment.getField(variable.name, context);
    }

    return environment.finalize(value).toString();
  }
}

abstract class Visitor<C, R> {
  R visitAll(Iterable<Node> nodes, [C context]);

  R visitIf(IfStatement ifStatement, [C context]);

  R visitText(Text text, [C context]);

  R visitVariable(Variable variable, [C context]);
}
