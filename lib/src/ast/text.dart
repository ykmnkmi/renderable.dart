part of '../ast.dart';

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C context]) {
    return visitor.visitText(this, context);
  }

  @override
  String toString() {
    return 'Text ${repr(text)}';
  }
}
