library visitor;

import 'ast.dart';

abstract class Visitor {
  void visitText(Text text);

  void visitVariable(Variable variable);

  void visitAll(List<Node> nodes) {
    for (Node node in nodes) {
      node.accept(this);
    }
  }
}

class Renderer extends Visitor {
  Renderer([StringBuffer buffer]) : _buffer = buffer ?? StringBuffer();

  final StringBuffer _buffer;

  Map<String, Object> _context;

  void reset(Map<String, Object> context) {
    _buffer.clear();
    _context = context;
  }

  @override
  void visitText(Text node) {
    _buffer.write(node.text);
  }

  @override
  void visitVariable(Variable node) {
    _buffer.write(_context[node.name]);
  }

  @override
  String toString() {
    return '$_buffer';
  }
}
