import 'exceptions.dart';
import 'visitor.dart';

abstract class Node {
  void accept(Visitor visitor);
}

abstract class Expression extends Node {}

class Name extends Expression {
  Name(this.name, [this.type = 'dynamic']);

  String name;

  String type;

  @override
  void accept(Visitor visitor) {
    return visitor.visitName(this);
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
  void accept(Visitor visitor) {
    visitor.visitConcat(this);
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
  void accept(Visitor visitor) {
    visitor.visitAttribute(this);
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
  void accept(Visitor visitor) {
    visitor.visitItem(this);
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
  void accept(Visitor visitor) {
    visitor.visitSlice(this);
  }

  @override
  String toString() {
    return 'Slice($expression, $start, $stop, $step)';
  }

  static List<Object> slice(List<Object> list, int start, [int? end, int? step]) {
    final result = <Object>[];
    final length = list.length;

    end ??= length;
    step ??= 1;

    if (start < 0) {
      start = length + start;
    }

    if (end < 0) {
      end = length + end;
    }

    if (step > 0) {
      for (var i = start; i < end; i += step) {
        result.add(list[i]);
      }
    } else {
      step = -step;

      for (var i = end - 1; i >= start; i -= step) {
        result.add(list[i]);
      }
    }

    return list;
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
  void accept(Visitor visitor) {
    visitor.visitCall(this);
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
  void accept(Visitor visitor) {
    visitor.visitFilter(this);
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
  void accept(Visitor visitor) {
    visitor.visitTest(this);
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
  void accept(Visitor visitor) {
    visitor.visitCompare(this);
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
  void accept(Visitor visitor) {
    visitor.visitCondition(this);
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
  void accept(Visitor visitor) {
    return visitor.visitData(this);
  }

  @override
  String toString() {
    return 'Data("${data.replaceAll('"', r'\"').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}")';
  }
}

class Constant<T> extends Literal {
  Constant(this.value);

  T value;

  @override
  void accept(Visitor visitor) {
    return visitor.visitConstant(this);
  }

  @override
  String toString() {
    return 'Constant<$T>($value)';
  }
}

class TupleLiteral extends Literal {
  TupleLiteral(this.values, {this.save = false});

  List<Expression> values;

  bool save;

  @override
  void accept(Visitor visitor) {
    visitor.visitTupleLiteral(this);
  }

  @override
  String toString() {
    return 'TupleLiteral($values)';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.values);

  List<Expression> values;

  @override
  void accept(Visitor visitor) {
    visitor.visitListLiteral(this);
  }

  @override
  String toString() {
    return 'ListLiteral($values)';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.pairs);

  List<Pair> pairs;

  @override
  void accept(Visitor visitor) {
    visitor.visitDictLiteral(this);
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
  void accept(Visitor visitor) {
    visitor.visitUnary(this);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $expression)';
  }
}

class Positive extends Unary {
  Positive(Expression expression) : super('+', expression);
}

class Negative extends Unary {
  Negative(Expression expression) : super('-', expression);
}

class Not extends Unary {
  Not(Expression expression) : super('not', expression);
}

abstract class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  String operator;

  Expression left;

  Expression right;

  @override
  void accept(Visitor visitor) {
    visitor.visitBinary(this);
  }

  @override
  String toString() {
    return '$runtimeType(\'$operator\', $left, $right)';
  }
}

class Pow extends Binary {
  Pow(Expression left, Expression right) : super('**', left, right);
}

class Mul extends Binary {
  Mul(Expression left, Expression right) : super('*', left, right);
}

class Div extends Binary {
  Div(Expression left, Expression right) : super('/', left, right);
}

class FloorDiv extends Binary {
  FloorDiv(Expression left, Expression right) : super('//', left, right);
}

class Mod extends Binary {
  Mod(Expression left, Expression right) : super('%', left, right);
}

class Add extends Binary {
  Add(Expression left, Expression right) : super('+', left, right);
}

class Sub extends Binary {
  Sub(Expression left, Expression right) : super('-', left, right);
}

class And extends Binary {
  And(Expression left, Expression right) : super('and', left, right);
}

class Or extends Binary {
  Or(Expression left, Expression right) : super('or', left, right);
}

abstract class Statement extends Node {}

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  void accept(Visitor visitor) {
    visitor.visitOutput(this);
  }

  @override
  String toString() {
    return 'Output($nodes)';
  }
}

class If extends Statement {
  If(this.test, this.body, this.elseIf, this.$else);

  Expression test;

  List<Node> body;

  List<Node> elseIf;

  List<Node> $else;

  @override
  void accept(Visitor visitor) {
    return visitor.visitIf(this);
  }

  @override
  String toString() {
    return 'If($test, $body, $elseIf, ${$else})';
  }
}

abstract class Helper extends Node {}

class Pair extends Helper {
  Pair(this.key, this.value);

  Expression key;

  Expression value;

  @override
  void accept(Visitor visitor) {
    visitor.visitPair(this);
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
  void accept(Visitor visitor) {
    visitor.visitKeyword(this);
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
  void accept(Visitor visitor) {
    visitor.visitOperand(this);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $expression)';
  }
}
