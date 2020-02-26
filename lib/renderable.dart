library dsx;

import 'package:petitparser/petitparser.dart' hide Parser;
import 'package:petitparser/petitparser.dart' as pp show Parser;

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
  factory Template(String source) => Parser().parse(source);

  const Template.fromNodes(this.nodes);

  final List<Node> nodes;

  @override
  void accept(Visitor visitor) {
    visitor.visitAll(nodes);
  }

  @override
  String render(Map<String, Object> context) {
    final StringBuffer buffer = StringBuffer();
    final Renderer renderer = Renderer(buffer, context);
    accept(renderer);
    return '$buffer';
  }

  @override
  String toString() => 'Template $nodes';
}

class Parser {
  static Parser _instance;

  static Parser Function() _checker = () {
    try {
      return _instance ??= Parser._();
    } finally {
      _checker = () => _instance;
    }
  };

  factory Parser() => _checker();

  Parser._() {
    identifier = (pattern('a-z') & pattern('a-z').star()).flatten();
    variableOpen = (string('{{') & whitespace().star()).pick<String>(0);
    variableClose = (whitespace().star() & string('}}')).pick<String>(1);
    variable = (variableOpen & identifier & variableClose).pick<String>(1).map<Node>((String name) => Variable(name));
    data = any().starLazy(variableOpen).flatten().map<Node>((String text) => Text(text));
    template = data.separatedBy<Node>(variable, optionalSeparatorAtEnd: true).end();
  }

  pp.Parser<String> identifier;
  pp.Parser<String> variableOpen;
  pp.Parser<String> variableClose;
  pp.Parser<Node> variable;
  pp.Parser<Node> data;
  pp.Parser<List<Node>> template;

  Template parse(String source) {
    final Result<List<Node>> parseResult = template.parse(source);
    if (parseResult.isFailure) throw parseResult;
    final List<Node> nodes = parseResult.value;
    return Template.fromNodes(nodes);
  }
}

extension TemplateString on String {
  Template parse() => Parser().parse(this);

  String render(Map<String, Object> context) => parse().render(context);
}
