library visitor;

import 'ast.dart';
import 'environment.dart';
import 'mirror.dart';

class Renderer<C> implements Visitor<C, Object> {
  final Environment environment;

  Renderer(this.environment);

  @override
  String toString() => 'Renderer<$C>()';

  @override
  String visitAll(Iterable<Node> nodes, [C? context]) =>
      nodes.map((node) => node.accept<C, Object>(this, context)).join();

  @override
  String visitText(Text text, [C? context]) => text.text;

  @override
  Object visitVariable(Variable variable, [C? context]) {
    // TODO: стойт ли использовать отдельный класс для рендера словаря?
    if (context is Map<String, Object>) {
      return context[variable.name] ?? '';
    }

    return getField<Object>(variable.name, context) ?? '';
  }
}

abstract class Visitor<C, R> {
  R visitAll(Iterable<Node> nodes, [C? context]);

  R visitText(Text text, [C? context]);

  R visitVariable(Variable variable, [C? context]);
}
