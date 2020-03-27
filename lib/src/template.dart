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
  String render([Map<String, Object> context = const <String, Object>{}]) {
    final Renderer renderer = Renderer();
    renderer.visitAll(nodes, context);
    return '$renderer';
  }

  @override
  String toString() {
    return 'Template $nodes';
  }
}

extension TemplateString on String {
  Template parse() {
    return Template(this);
  }

  String render([Map<String, Object> context = const <String, Object>{}]) {
    return parse().render(context);
  }
}
