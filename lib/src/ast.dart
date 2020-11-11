library ast;

import 'visitor.dart';

part 'ast/interpolation.dart';
part 'ast/expressions/test.dart';
part 'ast/statements/if.dart';

abstract class Node {
  static Node orList(List<Node> nodes) {
    if (nodes.length == 1) {
      return nodes[0];
    }

    return Interpolation(nodes);
  }

  void accept(Visitor visitor);
}

abstract class Expression extends Node {}

class Name implements Expression {
  const Name(this.name);

  final String name;

  @override
  void accept(Visitor visitor) {
    return visitor.visitName(this);
  }

  @override
  String toString() {
    return 'Name($name)';
  }
}

abstract class Literal implements Expression {
  const Literal();

  @override
  String toString() {
    return 'Literal()';
  }
}

class Text implements Literal {
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

class Constant<T> extends Literal {
  const Constant(this.value);

  final T value;

  @override
  void accept(Visitor visitor) {
    return visitor.visitLiteral(this);
  }

  @override
  String toString() {
    return 'Constant<$T>($value)';
  }
}

class TupleLiteral extends Literal {
  const TupleLiteral(this.items, {this.save = false});

  final List<Expression> items;

  final bool save;

  @override
  void accept(Visitor visitor) {
    visitor.visitTupleLiteral(this);
  }

  @override
  String toString() {
    return 'TupleLiteral($items)';
  }
}

class ListLiteral extends Literal {
  const ListLiteral(this.items);

  final List<Expression> items;

  @override
  void accept(Visitor visitor) {
    visitor.visitListLiteral(this);
  }

  @override
  String toString() {
    return 'ListLiteral($items)';
  }
}

class DictLiteral extends Literal {
  const DictLiteral(this.items);

  final List<Pair> items;

  @override
  void accept(Visitor visitor) {
    visitor.visitDictLiteral(this);
  }

  @override
  String toString() {
    return 'DictLiteral($items)';
  }
}

abstract class Statement extends Node {}

abstract class Helper extends Node {}

class Pair extends Helper {
  Pair(this.key, this.value);

  final Expression key;

  final Expression value;

  @override
  void accept(Visitor visitor) {
    visitor.visitPair(this);
  }

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}
