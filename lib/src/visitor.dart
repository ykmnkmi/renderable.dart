library visitor;

import 'ast.dart';

abstract class Visitor<C> {
  void visitText(Text text, C context);

  void visitVariable(Variable variable, C context);

  void visitAll(List<Node> nodes, C context) {
    for (Node node in nodes) {
      node.accept<C>(this, context);
    }
  }
}

class Renderer extends Visitor<Map<String, Object>> {
  Renderer([StringBuffer buffer]) : _buffer = buffer ?? StringBuffer();

  final StringBuffer _buffer;

  @override
  void visitText(Text node, _) {
    _buffer.write(node.text);
  }

  @override
  void visitVariable(Variable node, Map<String, Object> context) {
    _buffer.write(context[node.name]);
  }

  @override
  String toString() {
    return '$_buffer';
  }
}
