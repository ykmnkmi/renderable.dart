library template;

import 'ast.dart';
import 'parser.dart';
import 'interface.dart';
import 'visitor.dart';

class Template<C> implements Renderable<C> {
  final List<Node> nodes;

  factory Template(String source) => Template<C>.fromNodes(const Parser().parse(source));

  Template.fromNodes(Iterable<Node> nodes) : nodes = nodes.toList(growable: false);

  @override
  String render([C context]) => const Renderer<Object>().visitAll(nodes, context).toString();

  @override
  String toString() => 'Template $nodes';
}
