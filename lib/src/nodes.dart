import 'dart:math' as math;

import 'context.dart';
import 'exceptions.dart';
import 'tests.dart' as tests hide tests;
import 'visitor.dart';
import 'utils.dart';

class Impossible implements Exception {}

abstract class Node {
  R accept<C, R>(Visitor<C, R> visitor, C context);
}

abstract class Expression extends Node {}

class Name extends Expression {
  Name(this.name, [this.type = 'dynamic']);

  String name;

  String type;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitName(this, context);
  }

  @override
  String toString() {
    return 'Name($name, $type)';
  }
}

class Concat extends Expression {
  Concat(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConcat(this, context);
  }

  @override
  String toString() {
    return 'Concat($expressions)';
  }
}

class Attribute extends Expression {
  Attribute(this.attribute, this.expression);

  String attribute;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAttribute(this, context);
  }

  @override
  String toString() {
    return 'Attribute($attribute, $expression)';
  }
}

class Item extends Expression {
  Item(this.key, this.expression);

  Expression key;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitItem(this, context);
  }

  @override
  String toString() {
    return 'Item($key, $expression)';
  }
}

class Slice extends Expression {
  factory Slice.fromList(Expression expression, List<Expression?> expressions) {
    assert(expressions.isNotEmpty);
    assert(expressions.length <= 3);

    switch (expressions.length) {
      case 1:
        return Slice(expression, expressions[0]!);
      case 2:
        return Slice(expression, expressions[0]!, stop: expressions[1]);
      case 3:
        return Slice(expression, expressions[0]!, stop: expressions[1], step: expressions[2]);
      default:
        throw TemplateRuntimeError();
    }
  }

  Slice(this.expression, this.start, {this.stop, this.step});

  Expression expression;

  Expression start;

  Expression? stop;

  Expression? step;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSlice(this, context);
  }

  @override
  String toString() {
    return 'Slice($expression, $start, $stop, $step)';
  }

  static dynamic slice(dynamic list, int start, [int? stop, int? step]) {
    final length = list.length as int;
    stop ??= length;
    step ??= 1;
    return slice(list, start, stop, step);
  }
}

class Call extends Expression {
  Call(this.expression, {this.arguments = const <Expression>[], this.keywordArguments = const <Keyword>[], this.dArguments, this.dKeywordArguments});

  Expression expression;

  List<Expression> arguments;

  List<Keyword> keywordArguments;

  Expression? dArguments;

  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCall(this, context);
  }

  @override
  String toString() {
    return 'Call($expression, $arguments, $keywordArguments)';
  }
}

class Filter extends Expression {
  Filter(this.name, this.expression,
      {this.arguments = const <Expression>[], this.keywordArguments = const <Keyword>[], this.dArguments, this.dKeywordArguments});

  Filter.fromCall(this.name, this.expression, Call call)
      : arguments = call.arguments,
        keywordArguments = call.keywordArguments,
        dArguments = call.dArguments,
        dKeywordArguments = call.dKeywordArguments;

  String name;

  Expression expression;

  List<Expression> arguments;

  List<Keyword> keywordArguments;

  Expression? dArguments;

  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFilter(this, context);
  }

  @override
  String toString() {
    return 'Filter($name, $expression, $arguments, $keywordArguments, $dArguments, $dKeywordArguments)';
  }
}

class Test extends Expression {
  Test(this.name, this.expression, {this.arguments = const <Expression>[], this.keywordArguments = const <Keyword>[], this.dArguments, this.dKeywordArguments});

  Test.fromCall(this.name, this.expression, Call call)
      : arguments = call.arguments,
        keywordArguments = call.keywordArguments,
        dArguments = call.dArguments,
        dKeywordArguments = call.dKeywordArguments;

  String name;

  Expression expression;

  List<Expression> arguments;

  List<Keyword> keywordArguments;

  Expression? dArguments;

  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTest(this, context);
  }

  @override
  String toString() {
    return 'Test($name, $expression, $arguments, $keywordArguments, $dArguments, $dKeywordArguments)';
  }
}

class Compare extends Expression {
  Compare(this.expression, this.operands);

  Expression expression;

  List<Operand> operands;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCompare(this, context);
  }

  @override
  String toString() {
    return 'Compare($operands)';
  }
}

class Condition extends Expression {
  Condition(this.test, this.expression1, [this.expression2]);

  Expression test;

  Expression expression1;

  Expression? expression2;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitCondition(this, context);
  }

  @override
  String toString() {
    return 'Condition($test, $expression1, $expression2)';
  }
}

abstract class Literal extends Expression {
  @override
  String toString() {
    return 'Literal()';
  }
}

class Data extends Literal {
  Data([this.data = '']);

  String data;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitData(this, context);
  }

  @override
  String toString() {
    return 'Data("${data.replaceAll('"', r'\"').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}")';
  }
}

class Constant<T> extends Literal {
  Constant(this.value);

  T? value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitConstant(this, context);
  }

  @override
  String toString() {
    return 'Constant<$T>($value)';
  }
}

class TupleLiteral extends Literal {
  TupleLiteral(this.expressions, {this.save = false});

  List<Expression> expressions;

  bool save;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitTupleLiteral(this, context);
  }

  @override
  String toString() {
    return 'TupleLiteral($expressions)';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitListLiteral(this, context);
  }

  @override
  String toString() {
    return 'ListLiteral($expressions)';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.pairs);

  List<Pair> pairs;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDictLiteral(this, context);
  }

  @override
  String toString() {
    return 'DictLiteral($pairs)';
  }
}

abstract class Unary extends Expression {
  Unary(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitUnary(this, context);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $expression)';
  }
}

class Pos extends Unary {
  Pos(Expression expression) : super('+', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPos(this, context);
  }
}

class Neg extends Unary {
  Neg(Expression expression) : super('-', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNeg(this, context);
  }
}

class Not extends Unary {
  Not(Expression expression) : super('not', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitNot(this, context);
  }
}

abstract class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  String operator;

  Expression left;

  Expression right;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitBinary(this, context);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $left, $right)';
  }
}

class Pow extends Binary {
  Pow(Expression left, Expression right) : super('**', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPow(this, context);
  }
}

class Mul extends Binary {
  Mul(Expression left, Expression right) : super('*', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMul(this, context);
  }
}

class Div extends Binary {
  Div(Expression left, Expression right) : super('/', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitDiv(this, context);
  }
}

class FloorDiv extends Binary {
  FloorDiv(Expression left, Expression right) : super('//', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitFloorDiv(this, context);
  }
}

class Mod extends Binary {
  Mod(Expression left, Expression right) : super('%', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitMod(this, context);
  }
}

class Add extends Binary {
  Add(Expression left, Expression right) : super('+', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAdd(this, context);
  }
}

class Sub extends Binary {
  Sub(Expression left, Expression right) : super('-', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitSub(this, context);
  }
}

class And extends Binary {
  And(Expression left, Expression right) : super('and', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitAnd(this, context);
  }
}

class Or extends Binary {
  Or(Expression left, Expression right) : super('or', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOr(this, context);
  }
}

abstract class Statement extends Node {}

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOutput(this, context);
  }

  @override
  String toString() {
    return 'Output($nodes)';
  }
}

class If extends Statement {
  If(this.test, this.body, this.elseIf, this.else_);

  Expression test;

  List<Node> body;

  List<If> elseIf;

  List<Node> else_;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitIf(this, context);
  }

  @override
  String toString() {
    return 'If($test, $body, $elseIf, ${else_})';
  }
}

abstract class Helper extends Node {}

class Pair extends Helper {
  Pair(this.key, this.value);

  Expression key;

  Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitPair(this, context);
  }

  @override
  String toString() {
    return 'Pair($key, $value)';
  }
}

class Keyword extends Helper {
  Keyword(this.key, this.value);

  String key;

  Expression value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitKeyword(this, context);
  }

  @override
  String toString() {
    return 'Keyword($key, $value)';
  }
}

class Operand extends Helper {
  Operand(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, C context) {
    return visitor.visitOperand(this, context);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $expression)';
  }
}
