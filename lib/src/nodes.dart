library ast;

import 'exceptions.dart';
import 'visitor.dart';

abstract class Node {
  static Node orList(List<Node> nodes) {
    if (nodes.length == 1) {
      return nodes[0];
    }

    return Output(nodes);
  }

  const Node();

  void accept(Visitor visitor);
}

abstract class Expression extends Node {
  const Expression();
}

class Name implements Expression {
  const Name(this.name, [this.type = 'dynamic']);

  final String name;

  final String type;

  @override
  int get hashCode {
    return 'Name'.hashCode ^ name.hashCode ^ type.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Name && name == other.name && type == other.type;
  }

  @override
  void accept(Visitor visitor) {
    return visitor.visitName(this);
  }

  @override
  String toString() {
    return 'Name($name, $type)';
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

class Test extends Expression {
  const Test(this.name, this.expression);

  final String name;

  final Expression expression;

  @override
  void accept(Visitor visitor) {
    visitor.visitTest(this);
  }

  @override
  String toString() {
    return 'Test($name, $expression)';
  }
}

class Item extends Expression {
  const Item(this.key, this.expression);

  final Expression key;

  final Expression expression;

  @override
  void accept(Visitor visitor) {
    visitor.visitItem(this);
  }

  @override
  String toString() {
    return 'Item($key, $expression)';
  }
}

class Attribute extends Expression {
  const Attribute(this.attribute, this.expression);

  final String attribute;

  final Expression expression;

  @override
  void accept(Visitor visitor) {
    visitor.visitAttribute(this);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $expression)';
  }
}

class Slice extends Expression {
  factory Slice.fromList(Expression expression, List<Expression> expressions) {
    assert(expressions.isNotEmpty);
    assert(expressions.length <= 3);

    switch (expressions.length) {
      case 1:
        return Slice(expression, expressions[0]);
      case 2:
        return Slice(expression, expressions[0], expressions[1]);
      case 3:
        return Slice(expression, expressions[0], expressions[1], expressions[2]);
      default:
        throw TemplateRuntimeError();
    }
  }

  const Slice(this.expression, this.start, [this.stop, this.step]);

  final Expression expression;

  final Expression start;

  final Expression stop;

  final Expression step;

  @override
  void accept(Visitor visitor) {
    visitor.visitSlice(this);
  }

  @override
  String toString() {
    return 'Slice($expression, $start, $stop, $step)';
  }
}

abstract class Unary extends Expression {
  const Unary(this.operator, this.expression);

  final String operator;

  final Expression expression;

  @override
  void accept(Visitor visitor) {
    visitor.visitUnary(this);
  }

  @override
  String toString() {
    return 'Unary(\'$operator\', $expression)';
  }
}

class Not extends Unary {
  const Not(Expression item) : super('not', item);

  @override
  String toString() {
    return 'Not($expression)';
  }
}

class Negative extends Unary {
  const Negative(Expression item) : super('-', item);

  @override
  String toString() {
    return 'Negative($expression)';
  }
}

class Positive extends Unary {
  const Positive(Expression item) : super('+', item);

  @override
  String toString() {
    return 'Positive($expression)';
  }
}

abstract class Statement extends Node {
  const Statement();
}

class Output extends Statement {
  const Output(this.items);

  final List<Node> items;

  @override
  void accept(Visitor visitor) {
    visitor.visitOutput(this);
  }

  @override
  String toString() {
    return 'Interpolation($items)';
  }
}

class If extends Statement {
  const If(this.pairs, [this.orElse]);

  final Map<Test, Node> pairs;

  final Node orElse;

  @override
  void accept(Visitor visitor) {
    return visitor.visitIf(this);
  }

  @override
  String toString() {
    return 'If($pairs, $orElse)';
  }
}

abstract class Helper extends Node {
  const Helper();
}

class Pair extends Helper {
  const Pair(this.key, this.value);

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
