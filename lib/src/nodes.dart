import 'exceptions.dart';
import 'utils.dart';
import 'visitor.dart';

enum AssignContext {
  load,
  store,
  parameter,
}

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, [C? context]);
}

class Data extends Node {
  Data([this.data = '']);

  String data;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitData(this, context);
  }

  @override
  String toString() {
    return 'Data(\'${data.replaceAll('\'', '\\\'').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}\')';
  }
}

abstract class CanAssign {
  AssignContext? context;
}

abstract class Expression extends Node {}

class Name extends Expression implements CanAssign {
  Name(this.name, [this.context = AssignContext.load, this.type]);

  String name;

  @override
  AssignContext? context;

  String? type;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitName(this, context);
  }

  @override
  String toString() {
    if (type == null) {
      return 'Name($name)';
    }

    return 'Name($name, $type)';
  }
}

class NameSpaceReference extends Expression implements CanAssign {
  NameSpaceReference(this.name, this.attribute) : context = AssignContext.store;

  String name;

  String attribute;

  @override
  AssignContext? context;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    throw UnimplementedError();
  }
}

class Concat extends Expression {
  Concat(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitItem(this, context);
  }

  @override
  String toString() {
    return 'Item($key, $expression)';
  }
}

class Slice extends Expression {
  factory Slice.fromList(List<Expression?> expressions) {
    assert(expressions.length <= 3);

    switch (expressions.length) {
      case 0:
        return Slice();
      case 1:
        return Slice(start: expressions[0]);
      case 2:
        return Slice(start: expressions[0], stop: expressions[1]);
      case 3:
        return Slice(start: expressions[0], stop: expressions[1], step: expressions[2]);
      default:
        throw TemplateRuntimeError();
    }
  }

  Slice({this.start, this.stop, this.step});

  Expression? start;

  Expression? stop;

  Expression? step;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitSlice(this, context);
  }

  @override
  String toString() {
    var result = 'Slice(';

    if (start != null) {
      result += 'start: $start';
    }

    if (stop != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'stop: $stop';
    }

    if (step != null) {
      if (!result.endsWith('(')) {
        result += ', ';
      }

      result += 'step: $step';
    }

    return result + ')';
  }
}

class Call extends Expression {
  Call(
    this.expression, {
    this.arguments = const <Expression>[],
    this.keywordArguments = const <Keyword>[],
    this.dArguments,
    this.dKeywordArguments,
  });

  Expression expression;

  List<Expression> arguments;

  List<Keyword> keywordArguments;

  Expression? dArguments;

  Expression? dKeywordArguments;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitCall(this, context);
  }

  @override
  String toString() {
    var result = 'Call($expression';

    if (arguments.isNotEmpty) {
      result += ', ${arguments.join(', ')}';
    }

    if (keywordArguments.isNotEmpty) {
      result += ', ${keywordArguments.join(', ')}';
    }

    if (dArguments != null) {
      result += ', $dArguments';
    }

    if (dKeywordArguments != null) {
      result += ', $dKeywordArguments';
    }

    return result;
  }
}

class Filter extends Expression {
  Filter(
    this.name,
    this.expression, {
    this.arguments = const <Expression>[],
    this.keywordArguments = const <Keyword>[],
    this.dArguments,
    this.dKeywordArguments,
  });

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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFilter(this, context);
  }

  @override
  String toString() {
    var result = 'Filter(\'$name\', $expression';

    if (arguments.isNotEmpty) {
      result += ', ${arguments.join(', ')}';
    }

    if (keywordArguments.isNotEmpty) {
      result += ', ${keywordArguments.join(', ')}';
    }

    if (dArguments != null) {
      result += ', $dArguments';
    }

    if (dKeywordArguments != null) {
      result += ', $dKeywordArguments';
    }

    return result;
  }
}

class Test extends Expression {
  Test(
    this.name,
    this.expression, {
    this.arguments = const <Expression>[],
    this.keywordArguments = const <Keyword>[],
    this.dArguments,
    this.dKeywordArguments,
  });

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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitTest(this, context);
  }

  @override
  String toString() {
    var result = 'Test(\'$name\', $expression';

    if (arguments.isNotEmpty) {
      result += ', ${arguments.join(', ')}';
    }

    if (keywordArguments.isNotEmpty) {
      result += ', ${keywordArguments.join(', ')}';
    }

    if (dArguments != null) {
      result += ', $dArguments';
    }

    if (dKeywordArguments != null) {
      result += ', $dKeywordArguments';
    }

    return result;
  }
}

class Compare extends Expression {
  Compare(this.expression, this.operands);

  Expression expression;

  List<Operand> operands;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitCompare(this, context);
  }

  @override
  String toString() {
    return 'Compare($expression, $operands)';
  }
}

class Condition extends Expression {
  Condition(this.test, this.expression1, [this.expression2]);

  Expression test;

  Expression expression1;

  Expression? expression2;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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

class Constant<T> extends Literal {
  static Constant<bool> get False {
    return Constant<bool>(false);
  }

  static Constant<bool> get True {
    return Constant<bool>(true);
  }

  Constant(this.value);

  T? value;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitConstant(this, context);
  }

  @override
  String toString() {
    return 'Constant<$T>(${represent(value)})';
  }
}

class TupleLiteral extends Literal implements CanAssign {
  TupleLiteral(this.expressions, [this.context = AssignContext.load]);

  List<Expression> expressions;

  @override
  AssignContext? context;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitTupleLiteral(this, context);
  }

  @override
  String toString() {
    return 'Tuple(${expressions.join(', ')})';
  }
}

class ListLiteral extends Literal {
  ListLiteral(this.expressions);

  List<Expression> expressions;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitListLiteral(this, context);
  }

  @override
  String toString() {
    return 'List(${expressions.join(', ')})';
  }
}

class DictLiteral extends Literal {
  DictLiteral(this.pairs);

  List<Pair> pairs;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitDictLiteral(this, context);
  }

  @override
  String toString() {
    return 'Dict(${pairs.join(', ')})';
  }
}

abstract class Unary extends Expression {
  Unary(this.operator, this.expression);

  String operator;

  Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitPos(this, context);
  }

  @override
  String toString() {
    return 'Pos($expression)';
  }
}

class Neg extends Unary {
  Neg(Expression expression) : super('-', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitNeg(this, context);
  }

  @override
  String toString() {
    return 'Neg($expression)';
  }
}

class Not extends Unary {
  Not(Expression expression) : super('not', expression);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitNot(this, context);
  }

  @override
  String toString() {
    return 'Not($expression)';
  }
}

abstract class Binary extends Expression {
  Binary(this.operator, this.left, this.right);

  String operator;

  Expression left;

  Expression right;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitPow(this, context);
  }

  @override
  String toString() {
    return 'Pow($left, $right)';
  }
}

class Mul extends Binary {
  Mul(Expression left, Expression right) : super('*', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitMul(this, context);
  }

  @override
  String toString() {
    return 'Mul($left, $right)';
  }
}

class Div extends Binary {
  Div(Expression left, Expression right) : super('/', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitDiv(this, context);
  }

  @override
  String toString() {
    return 'Div($left, $right)';
  }
}

class FloorDiv extends Binary {
  FloorDiv(Expression left, Expression right) : super('//', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFloorDiv(this, context);
  }

  @override
  String toString() {
    return 'FloorDiv($left, $right)';
  }
}

class Mod extends Binary {
  Mod(Expression left, Expression right) : super('%', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitMod(this, context);
  }

  @override
  String toString() {
    return 'Mod($left, $right)';
  }
}

class Add extends Binary {
  Add(Expression left, Expression right) : super('+', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAdd(this, context);
  }

  @override
  String toString() {
    return 'Add($left, $right)';
  }
}

class Sub extends Binary {
  Sub(Expression left, Expression right) : super('-', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitSub(this, context);
  }

  @override
  String toString() {
    return 'Sub($left, $right)';
  }
}

class And extends Binary {
  And(Expression left, Expression right) : super('and', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAnd(this, context);
  }

  @override
  String toString() {
    return 'And($left, $right)';
  }
}

class Or extends Binary {
  Or(Expression left, Expression right) : super('or', left, right);

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOr(this, context);
  }

  @override
  String toString() {
    return 'Or($left, $right)';
  }
}

abstract class Statement extends Node {}

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOutput(this, context);
  }

  @override
  String toString() {
    return 'Output($nodes)';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body);

  Expression target;

  Expression iterable;

  List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFor(this, context);
  }

  @override
  String toString() {
    return 'For()';
  }
}

class If extends Statement {
  If({Expression? test, List<Node>? body, this.elseIf, this.else_})
      : test = test ?? Constant.False,
        body = body ?? <Node>[];

  Expression test;

  List<Node> body;

  List<If>? elseIf;

  List<Node>? else_;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
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
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOperand(this, context);
  }

  @override
  String toString() {
    return 'Operand(\'$operator\', $expression)';
  }
}
