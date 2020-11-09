part of '../ast.dart';

class Text implements Node {
  const Text(this.text);

  final String text;

  @override
  void accept(Visitor visitor) {
    return visitor.visitText(this);
  }

  @override
  String toString() {
    return 'Text("${text.replaceAll('"', r'\"').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}")';
  }
}
