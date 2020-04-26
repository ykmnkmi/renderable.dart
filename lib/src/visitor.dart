library visitor;

import 'ast.dart';
import 'utils.dart';

class Renderer<C> implements Visitor<C, Object> {
  const Renderer();

  @override
  String toString() => 'Evaluator()';

  @override
  String visitAll(List<Node> nodes, C context) =>
      nodes.map((Node node) => node.accept<C, Object>(this, context)).join();

  @override
  String visitText(Text node, C context) => node.text;

  @override
  Object visitVariable(Variable node, C context) => getField<Object>(node.name, context);
}

abstract class Visitor<C, R> {
  R visitAll(List<Node> nodes, C context);

  R visitText(Text text, C context);

  R visitVariable(Variable variable, C context);
}
