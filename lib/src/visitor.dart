library visitor;

import 'ast.dart';

class Renderer implements Visitor<Map<String, Object>, Object> {
  const Renderer();

  @override
  String toString() => 'Evaluator()';

  @override
  String visitAll(List<Node> nodes, Map<String, Object> context) =>
      nodes.map((Node node) => node.accept<Map<String, Object>, Object>(this, context)).join();

  @override
  String visitText(Text node, Map<String, Object> context) => node.text;

  @override
  Object visitVariable(Variable node, Map<String, Object> context) => context[node.name];
}

abstract class Visitor<C, R> {
  R visitAll(List<Node> nodes, C context);

  R visitText(Text text, C context);

  R visitVariable(Variable variable, C context);
}
