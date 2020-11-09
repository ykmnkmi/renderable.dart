part of '../ast.dart';

class Comment implements Node {
  const Comment(this.text);

  final String text;

  @override
  void accept(Visitor visitor) {
    return visitor.visitComment(this);
  }

  @override
  String toString() {
    return 'Comment("${text.replaceAll('"', r'\"').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}")';
  }
}
