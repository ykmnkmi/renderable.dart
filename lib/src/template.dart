library template;

import 'ast.dart';
import 'generator.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Renderable<C> {
  String render([C context]);
}

class Template<C> implements Renderable<C> {
  final List<Node> nodes;

  factory Template(String source) => Template<C>.fromNodes(const Parser().parse(source));

  Template.fromNodes(Iterable<Node> nodes) : nodes = nodes.toList(growable: false);

  const factory Template.generate(String path) = GeneratedTemplate<C>;

  @override
  String render([C context]) => const Renderer<Object>().visitAll(nodes, context).toString();

  @override
  String toString() => 'Template $nodes';
}
