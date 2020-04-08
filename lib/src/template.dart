library template;

import 'ast.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Renderable {
  String render([Map<String, Object> context]);
}

class Template implements Renderable {
  factory Template(String source) => Template.fromNodes(const Parser().parse(source));

  Template.fromNodes(Iterable<Node> nodes) : nodes = nodes.toList(growable: false);

  final List<Node> nodes;

  @override
  String render([Map<String, Object> context = const <String, Object>{}]) =>
      const Evaluator().visitAll(nodes, context).toString();

  @override
  String toString() => 'Template $nodes';
}
