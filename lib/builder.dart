import 'src/nodes.dart';
import 'src/visitor.dart';

class Frame {}

class Compiler extends Visitor<Frame, String> {
  Compiler(this.template);

  final String template;

  String visit(List<Node> nodes) {
    throw UnimplementedError();
  }

  @override
  String visitAttribute(Attribute attribute, [Frame? context]) {
    // TODO: implement visitAttribute
    throw UnimplementedError();
  }

  @override
  String visitAssign(Assign assign, [Frame? context]) {
    // TODO: implement visitAssign
    throw UnimplementedError();
  }

  @override
  String visitAssignBlock(AssignBlock assign, [Frame? context]) {
    // TODO: implement visitAssignBlock
    throw UnimplementedError();
  }

  @override
  String visitBinary(Binary binary, [Frame? context]) {
    // TODO: implement visitBinary
    throw UnimplementedError();
  }

  @override
  String visitCall(Call call, [Frame? context]) {
    // TODO: implement visitCall
    throw UnimplementedError();
  }

  @override
  String visitCompare(Compare compare, [Frame? context]) {
    // TODO: implement visitCompare
    throw UnimplementedError();
  }

  @override
  String visitConcat(Concat concat, [Frame? context]) {
    // TODO: implement visitConcat
    throw UnimplementedError();
  }

  @override
  String visitCondition(Condition condition, [Frame? context]) {
    // TODO: implement visitCondition
    throw UnimplementedError();
  }

  @override
  String visitConstant(Constant<Object?> constant, [Frame? context]) {
    // TODO: implement visitConstant
    throw UnimplementedError();
  }

  @override
  String visitData(Data data, [Frame? context]) {
    // TODO: implement visitData
    throw UnimplementedError();
  }

  @override
  String visitDictLiteral(DictLiteral dict, [Frame? context]) {
    // TODO: implement visitDictLiteral
    throw UnimplementedError();
  }

  @override
  String visitFilter(Filter filter, [Frame? context]) {
    // TODO: implement visitFilter
    throw UnimplementedError();
  }

  @override
  String visitFor(For forNode, [Frame? context]) {
    // TODO: implement visitFor
    throw UnimplementedError();
  }

  @override
  String visitIf(If ifNode, [Frame? context]) {
    // TODO: implement visitIf
    throw UnimplementedError();
  }

  @override
  String visitItem(Item item, [Frame? context]) {
    // TODO: implement visitItem
    throw UnimplementedError();
  }

  @override
  String visitKeyword(Keyword keyword, [Frame? context]) {
    // TODO: implement visitKeyword
    throw UnimplementedError();
  }

  @override
  String visitListLiteral(ListLiteral list, [Frame? context]) {
    // TODO: implement visitListLiteral
    throw UnimplementedError();
  }

  @override
  String visitName(Name name, [Frame? context]) {
    // TODO: implement visitName
    throw UnimplementedError();
  }

  @override
  String visitNamespaceReference(NamespaceReference reference, [Frame? context]) {
    // TODO: implement visitNamespaceReference
    throw UnimplementedError();
  }

  @override
  String visitOperand(Operand operand, [Frame? context]) {
    // TODO: implement visitOperand
    throw UnimplementedError();
  }

  @override
  String visitOutput(Output output, [Frame? context]) {
    // TODO: implement visitOutput
    throw UnimplementedError();
  }

  @override
  String visitPair(Pair pair, [Frame? context]) {
    // TODO: implement visitPair
    throw UnimplementedError();
  }

  @override
  String visitSlice(Slice slice, [Frame? context]) {
    // TODO: implement visitSlice
    throw UnimplementedError();
  }

  @override
  String visitTest(Test test, [Frame? context]) {
    // TODO: implement visitTest
    throw UnimplementedError();
  }

  @override
  String visitTupleLiteral(TupleLiteral tuple, [Frame? context]) {
    // TODO: implement visitTupleLiteral
    throw UnimplementedError();
  }

  @override
  String visitUnary(Unary unary, [Frame? context]) {
    // TODO: implement visitUnary
    throw UnimplementedError();
  }

  @override
  String visitWith(With wiz, [Frame? context]) {
    // TODO: implement visitWith
    throw UnimplementedError();
  }
}
