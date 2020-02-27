library dsx;

abstract class Visitor {
  void visitText(Text text);

  void visitVariable(Variable variable);

  void visitAll(List<Node> nodes) {
    for (Node node in nodes) {
      node.accept(this);
    }
  }
}

abstract class Node {
  void accept(Visitor visitor);
}

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  void accept(Visitor visitor) {
    visitor.visitText(this);
  }

  @override
  String toString() => 'Text $text';
}

class Variable implements Node {
  const Variable(this.name);

  final String name;

  @override
  void accept(Visitor visitor) {
    visitor.visitVariable(this);
  }

  @override
  String toString() => 'Variable $name';
}

abstract class Renderable {
  String render(Map<String, Object> context);
}

class Renderer extends Visitor {
  Renderer(this.buffer, Map<String, Object> context) : context = Map<String, Object>.unmodifiable(context);

  final StringBuffer buffer;

  final Map<String, Object> context;

  @override
  void visitText(Text node) {
    buffer.write(node.text);
  }

  @override
  void visitVariable(Variable node) {
    buffer.write(context[node.name]);
  }
}

class Template implements Node, Renderable {
  factory Template(String source) => const Parser().parse(source);

  Template.fromNodes(this.nodes) : buffer = StringBuffer();

  final List<Node> nodes;

  final StringBuffer buffer;

  @override
  void accept(Visitor visitor) {
    visitor.visitAll(nodes);
  }

  @override
  String render(Map<String, Object> context) {
    buffer.clear();
    accept(Renderer(buffer, context));
    return '$buffer';
  }

  @override
  String toString() => 'Template $nodes';
}

class Parser {
  const Parser();

  Template parse(String source) {
    return null;
  }
}

extension TemplateString on String {
  Template parse() => const Parser().parse(this);

  String render(Map<String, Object> context) => parse().render(context);
}
