library template;

import 'ast.dart';
import 'parser.dart';
import 'visitor.dart';

abstract class Renderable {
  String render([Map<String, Object> context]);
}

class Template implements Renderable {
  factory Template(String source) {
    final List<Node> nodes = Parser().parse(source);
    return Template.fromNodes(nodes);
  }

  Template.fromNodes(this.nodes);

  final List<Node> nodes;

  @override
  String render([Map<String, Object> context = const <String, Object>{}]) => const Renderer().visitAll(nodes, context);

  @override
  String toString() => 'Template $nodes';
}

extension TemplateString on String {
  Template parse() => Template(this);

  String render([Map<String, Object> context = const <String, Object>{}]) => parse().render(context);
}
