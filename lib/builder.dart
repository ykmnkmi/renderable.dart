import 'src/enirvonment.dart';
import 'src/nodes.dart';
import 'src/visitor.dart';

abstract class Frame {}

class Compiler extends Visitor<Frame, String> {
  Compiler(this.template);

  final String template;

  String visit(List<Node> nodes) {
    throw UnimplementedError();
  }

  @override
  String visitAssign(Assign node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitAssignBlock(AssignBlock node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitAttribute(Attribute node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitBinary(Binary node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitBlock(Block node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitCall(Call node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitCompare(Compare node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitConcat(Concat node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitCondition(Condition node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitConstant(Constant<Object?> node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitContextModifier(ScopedContextModifier node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitData(Data node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitDictLiteral(DictLiteral node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitDo(Do node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitExtends(Extends node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitExtendedTemplate(ExtendedTemplate node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitFilter(Filter node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitFor(For node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitIf(If node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitInclude(Include node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitItem(Item node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitKeyword(Keyword node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitListLiteral(ListLiteral node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitName(Name node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitNamespaceReference(NamespaceReference node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitOperand(Operand node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitOutput(Output node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitPair(Pair node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitScope(Scope node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitSlice(Slice node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitTemplate(Template node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitTest(Test node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitTupleLiteral(TupleLiteral node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitUnary(Unary node, [Frame? context]) {
    throw UnimplementedError();
  }

  @override
  String visitWith(With node, [Frame? context]) {
    throw UnimplementedError();
  }
}
