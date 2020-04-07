library visitor;

import 'package:meta/meta.dart';

import 'ast.dart';

abstract class Visitor<C, R> {
  R visitText(Text text, C context);

  R visitVariable(Variable variable, C context);

  R visitAll(List<Node> nodes, C context);
}

class Evaluator implements Visitor<Map<String, Object>, Object> {
  @literal
  const Evaluator();

  @override
  String visitText(Text node, Map<String, Object> context) => node.text;

  @override
  Object visitVariable(Variable node, Map<String, Object> context) => context[node.name];

  @override
  String visitAll(List<Node> nodes, Map<String, Object> context) =>
      nodes.map((Node node) => node.accept<Map<String, Object>, Object>(this, context)).join();

  @override
  String toString() => 'Evaluator()';
}
