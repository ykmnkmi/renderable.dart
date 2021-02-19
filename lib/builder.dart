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
  String visitAssign(Assign node, [Frame? context]) {
    // TODO: implement visitAssign
    throw UnimplementedError();
  }

  @override
  String visitAssignBlock(AssignBlock node, [Frame? context]) {
    // TODO: implement visitAssignBlock
    throw UnimplementedError();
  }

  @override
  String visitAttribute(Attribute node, [Frame? context]) {
    // TODO: implement visitAttribute
    throw UnimplementedError();
  }

  @override
  String visitBinary(Binary node, [Frame? context]) {
    // TODO: implement visitBinary
    throw UnimplementedError();
  }

  @override
  String visitCall(Call node, [Frame? context]) {
    // TODO: implement visitCall
    throw UnimplementedError();
  }

  @override
  String visitCompare(Compare node, [Frame? context]) {
    // TODO: implement visitCompare
    throw UnimplementedError();
  }

  @override
  String visitConcat(Concat node, [Frame? context]) {
    // TODO: implement visitConcat
    throw UnimplementedError();
  }

  @override
  String visitCondition(Condition node, [Frame? context]) {
    // TODO: implement visitCondition
    throw UnimplementedError();
  }

  @override
  String visitConstant(Constant<Object?> node, [Frame? context]) {
    // TODO: implement visitConstant
    throw UnimplementedError();
  }

  @override
  String visitData(Data node, [Frame? context]) {
    // TODO: implement visitData
    throw UnimplementedError();
  }

  @override
  String visitDictLiteral(DictLiteral node, [Frame? context]) {
    // TODO: implement visitDictLiteral
    throw UnimplementedError();
  }

  @override
  String visitFilter(Filter node, [Frame? context]) {
    // TODO: implement visitFilter
    throw UnimplementedError();
  }

  @override
  String visitFor(For node, [Frame? context]) {
    // TODO: implement visitFor
    throw UnimplementedError();
  }

  @override
  String visitIf(If node, [Frame? context]) {
    // TODO: implement visitIf
    throw UnimplementedError();
  }

  @override
  String visitInclude(Include node, [Frame? context]) {
    // TODO: implement visitInclude
    throw UnimplementedError();
  }

  @override
  String visitItem(Item node, [Frame? context]) {
    // TODO: implement visitItem
    throw UnimplementedError();
  }

  @override
  String visitKeyword(Keyword node, [Frame? context]) {
    // TODO: implement visitKeyword
    throw UnimplementedError();
  }

  @override
  String visitListLiteral(ListLiteral node, [Frame? context]) {
    // TODO: implement visitListLiteral
    throw UnimplementedError();
  }

  @override
  String visitName(Name node, [Frame? context]) {
    // TODO: implement visitName
    throw UnimplementedError();
  }

  @override
  String visitNamespaceReference(NamespaceReference node, [Frame? context]) {
    // TODO: implement visitNamespaceReference
    throw UnimplementedError();
  }

  @override
  String visitOperand(Operand node, [Frame? context]) {
    // TODO: implement visitOperand
    throw UnimplementedError();
  }

  @override
  String visitOutput(Output node, [Frame? context]) {
    // TODO: implement visitOutput
    throw UnimplementedError();
  }

  @override
  String visitPair(Pair node, [Frame? context]) {
    // TODO: implement visitPair
    throw UnimplementedError();
  }

  @override
  String visitSlice(Slice node, [Frame? context]) {
    // TODO: implement visitSlice
    throw UnimplementedError();
  }

  @override
  String visitTest(Test node, [Frame? context]) {
    // TODO: implement visitTest
    throw UnimplementedError();
  }

  @override
  String visitTupleLiteral(TupleLiteral node, [Frame? context]) {
    // TODO: implement visitTupleLiteral
    throw UnimplementedError();
  }

  @override
  String visitUnary(Unary node, [Frame? context]) {
    // TODO: implement visitUnary
    throw UnimplementedError();
  }

  @override
  String visitWith(With node, [Frame? context]) {
    // TODO: implement visitWith
    throw UnimplementedError();
  }
}
