library ast;

import 'visitor.dart';

abstract class Node {
  void accept<C>(Visitor<C> visitor, C context);
}

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  void accept<C>(Visitor<C> visitor, C context) {
    visitor.visitText(this, context);
  }

  @override
  String toString() => 'Text $text';
}

class Variable implements Node {
  const Variable(this.name);

  final String name;

  @override
  void accept<C>(Visitor<C> visitor, C context) {
    visitor.visitVariable(this, context);
  }

  @override
  String toString() => 'Variable $name';
}
