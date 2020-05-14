library template;

import 'ast.dart';
import 'env.dart';
import 'parser.dart';
import 'interface.dart';
import 'visitor.dart';

class Template<C> implements Renderable<C> {
  final List<Node> nodes;

  factory Template(String source) {
    final environment = Environment();
    return Template<C>.fromNodes(Parser(environment).parse(source));
  }

  Template.fromNodes(Iterable<Node> nodes) : nodes = nodes.toList(growable: false);

  @override
  String render([C context]) => /* TODO: profile */ Renderer<C>().visitAll(nodes, context).toString();

  @override
  String toString() => 'Template $nodes';
}
