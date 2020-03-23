library template;

import 'ast.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Renderable {
  String render(Map<String, Object> context);
}

class Template implements Renderable {
  factory Template(String source) => const Parser().parse(source);

  Template.fromNodes(this.nodes) : _renderer = Renderer();

  final List<Node> nodes;

  final Renderer _renderer;

  @override
  String render([Map<String, Object> context = const <String, Object>{}]) {
    _renderer.reset(context);
    _renderer.visitAll(nodes);
    return '$_renderer';
  }

  @override
  String toString() => 'Template $nodes';
}
