part of '../ast.dart';

class Text implements Node {
  final String text;

  const Text(this.text);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) => visitor.visitText(this, context);

  @override
  String toString() => 'Text $text';
}