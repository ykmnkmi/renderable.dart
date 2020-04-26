library template;

import 'ast.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Renderable {
  String render([Map<String, Object> context]);
}

class Template implements Renderable {
  final List<Node> nodes;

  factory Template(String source) => Template.fromNodes(const Parser().parse(source));

  Template.fromNodes(Iterable<Node> nodes) : nodes = nodes.toList(growable: false);

  @override
  String render([Map<String, Object> context = const <String, Object>{}]) =>
      const Renderer().visitAll(nodes, context).toString();

  @override
  String toString() => 'Template $nodes';
}
