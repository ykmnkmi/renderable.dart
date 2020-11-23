import 'package:renderable/core.dart';

class Environment extends Configuration {
  Environment({
    String commentBegin = '{#',
    String commentEnd = '#}',
    String variableBegin = '{{',
    String variableEnd = '}}',
    String blockBegin = '{%',
    String blockEnd = '%}',
    String lineCommentPrefix = '##',
    String lineStatementPrefix = '#',
    bool lStripBlocks = false,
    bool trimBlocks = false,
    String newLine = '\n',
    bool keepTrailingNewLine = false,
  })  : filters = <String, Function>{},
        tests = <String, Function>{},
        super(
          commentBegin: commentBegin,
          commentEnd: commentEnd,
          variableBegin: variableBegin,
          variableEnd: variableEnd,
          blockBegin: blockBegin,
          blockEnd: blockEnd,
          lineCommentPrefix: lineCommentPrefix,
          lineStatementPrefix: lineStatementPrefix,
          lStripBlocks: lStripBlocks,
          trimBlocks: trimBlocks,
          newLine: newLine,
          keepTrailingNewLine: keepTrailingNewLine,
        ) {}

  final Map<String, Function> filters;

  final Map<String, Function> tests;

  @override
  Environment change({
    String commentBegin,
    String commentEnd,
    String variableBegin,
    String variableEnd,
    String blockBegin,
    String blockEnd,
    String lineCommentPrefix,
    String lineStatementPrefix,
    bool lStripBlocks,
    bool trimBlocks,
    String newLine,
    bool keepTrailingNewLine,
  }) {
    return Environment(
      commentBegin: commentBegin,
      commentEnd: commentEnd,
      variableBegin: variableBegin,
      variableEnd: variableEnd,
      blockBegin: blockBegin,
      blockEnd: blockEnd,
      lineCommentPrefix: lineCommentPrefix,
      lineStatementPrefix: lineStatementPrefix,
      lStripBlocks: lStripBlocks,
      trimBlocks: trimBlocks,
      newLine: newLine,
      keepTrailingNewLine: keepTrailingNewLine,
    );
  }
}

class Template extends Renderable {
  factory Template(
    String source, {
    String path,
    Environment parent,
    String commentBegin = '{#',
    String commentEnd = '#}',
    String variableBegin = '{{',
    String variableEnd = '}}',
    String blockBegin = '{%',
    String blockEnd = '%}',
    String lineCommentPrefix = '##',
    String lineStatementPrefix = '#',
    bool lStripBlocks = false,
    bool trimBlocks = false,
    String newLine = '\n',
    bool keepTrailingNewLine = false,
  }) {
    Environment environment;

    if (parent != null) {
      environment = parent.change(
        commentBegin: commentBegin,
        commentEnd: commentEnd,
        variableBegin: variableBegin,
        variableEnd: variableEnd,
        blockBegin: blockBegin,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        lStripBlocks: lStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
      );
    } else {
      environment = Environment(
        commentBegin: commentBegin,
        commentEnd: commentEnd,
        variableBegin: variableBegin,
        variableEnd: variableEnd,
        blockBegin: blockBegin,
        blockEnd: blockEnd,
        lineCommentPrefix: lineCommentPrefix,
        lineStatementPrefix: lineStatementPrefix,
        lStripBlocks: lStripBlocks,
        trimBlocks: trimBlocks,
        newLine: newLine,
        keepTrailingNewLine: keepTrailingNewLine,
      );
    }

    final body = Parser(environment).parse(source, path: path);
    return Template.parsed(environment, body, path);
  }

  Template.parsed(this.environment, this.body, [this.path]);

  final Environment environment;

  final Node body;

  final String path;

  @override
  String render([Map<String, Object> context]) {
    return Renderer(body, context).toString();
  }
}

class Renderer implements Visitor {
  Renderer(Node node, [Map<String, Object> context])
      : buffer = StringBuffer(),
        contexts = <Map<String, Object>>[context ?? <String, Object>{}] {
    node.accept(this);
  }

  final StringBuffer buffer;

  final List<Map<String, Object>> contexts;

  @override
  String toString() {
    return buffer.toString();
  }

  @override
  void visitAttribute(Attribute node) {
    throw 'implement visitAttribute';
  }

  @override
  void visitBinary(Binary node) {
    throw 'implement visitBinary';
  }

  @override
  void visitCall(Call node) {
    throw 'implement visitCall';
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  void visitConcat(Concat node) {
    throw 'implement visitConcat';
  }

  @override
  void visitCondition(Condition node) {
    throw 'implement visitCondition';
  }

  @override
  void visitConstant(Constant<Object> node) {
    throw 'implement visitConstant';
  }

  @override
  void visitData(Data node) {
    throw 'implement visitData';
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    throw 'implement visitDictLiteral';
  }

  @override
  void visitFilter(Filter node) {
    throw 'implement visitFilter';
  }

  @override
  void visitIf(If node) {
    throw 'implement visitIf';
  }

  @override
  void visitItem(Item node) {
    throw 'implement visitItem';
  }

  @override
  void visitKeyword(Keyword node) {
    throw 'implement visitKeyword';
  }

  @override
  void visitListLiteral(ListLiteral node) {
    throw 'implement visitListLiteral';
  }

  @override
  void visitName(Name node) {
    throw 'implement visitName';
  }

  @override
  void visitOperand(Operand node) {
    throw 'implement visitOperand';
  }

  @override
  void visitOutput(Output node) {
    throw 'implement visitOutput';
  }

  @override
  void visitPair(Pair node) {
    throw 'implement visitPair';
  }

  @override
  void visitSlice(Slice node) {
    throw 'implement visitSlice';
  }

  @override
  void visitTest(Test node) {
    throw 'implement visitTest';
  }

  @override
  void visitTupleLiteral(TupleLiteral node) {
    throw 'implement visitTupleLiteral';
  }

  @override
  void visitUnary(Unary node) {
    throw 'implement visitUnary';
  }
}
