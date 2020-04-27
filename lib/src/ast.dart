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

abstract class Expression extends Node {}

class Name implements Expression {
  final String name;

  const Name(this.name);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) => visitor.visitName(this, context);

  @override
  String toString() => 'Name $name';
}
