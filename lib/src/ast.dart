library ast;

import 'visitor.dart';

abstract class Node {
  R accept<C, R>(Visitor<C, R> visitor, C context);
}

class Text implements Node {
  final String text;

  const Text(this.text);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) => visitor.visitText(this, context);

  @override
  String toString() => 'Text $text';
}

class Variable implements Node {
  final String name;

  const Variable(this.name);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) => visitor.visitVariable(this, context);

  @override
  String toString() => 'Variable $name';
}
