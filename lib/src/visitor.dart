library visitor;

import 'ast.dart';
import 'mirror.dart';

class Renderer<C> implements Visitor<C, Object> {
  const Renderer();

  @override
  String toString() => 'Renderer<$C>()';

  @override
  String visitAll(Iterable<Node> nodes, C context) =>
      nodes.map((Node node) => node.accept<C, Object>(this, context)).join();

  @override
  Object visitVariable(Variable variable, C context) => getField<Object>(variable.name, context);

  @override
  String visitText(Text text, C context) => text.text;
}

abstract class Visitor<C, R> {
  R visitAll(Iterable<Node> nodes, C context);

  R visitVariable(Variable variable, C context);

  R visitText(Text text, C context);
}
