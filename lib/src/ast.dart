library ast;

import 'visitor.dart';

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

