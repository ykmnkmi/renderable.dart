library visitor;

import 'package:meta/meta.dart';

import 'ast.dart';

abstract class Visitor<C, R> {
  R visitText(Text text, C context);

  R visitVariable(Variable variable, C context);

  R visitAll(List<Node> nodes, C context);
}

class Renderer implements Visitor<Map<String, Object>, String> {
  @literal
  const Renderer();

  @override
  String visitText(Text node, _) => node.text;

  @override
  String visitVariable(Variable node, Map<String, Object> context) => '${context[node.name]}';

  @override
  String visitAll(List<Node> nodes, Map<String, Object> context) =>
      nodes.map((Node node) => node.accept<Map<String, Object>, String>(this, context)).join();

  @override
  String toString() => 'Renderer()';
}
