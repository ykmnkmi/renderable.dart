// ignore_for_file: import_of_legacy_library_into_null_safe
import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'src/configuration.dart';
import 'src/defaults.dart' as defaults;
import 'src/nodes.dart';
import 'src/parser.dart';
import 'src/visitor.dart';

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder.fromConfig(options.config);
}

class HtmlTemplateBuilder extends Builder {
  factory HtmlTemplateBuilder.fromConfig(Map<String, Object?> config) {
    return HtmlTemplateBuilder(
      Configuration(
        commentBegin: config['comment_begin'] as String? ?? defaults.commentBegin,
        commentEnd: config['comment_end'] as String? ?? defaults.commentEnd,
        variableBegin: config['variable_begin'] as String? ?? defaults.variableBegin,
        variableEnd: config['variable_end'] as String? ?? defaults.variableEnd,
        blockBegin: config['block_begin'] as String? ?? defaults.blockBegin,
        blockEnd: config['block_end'] as String? ?? defaults.blockEnd,
      ),
    );
  }

  HtmlTemplateBuilder(this.environment) : formatter = DartFormatter();

  final Configuration environment;

  final DartFormatter formatter;

  @override
  Map<String, List<String>> get buildExtensions {
    return <String, List<String>>{
      '.html': ['.html.dart'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) {
    final inputId = buildStep.inputId;

    var name = path.basenameWithoutExtension(inputId.path);
    name = name[0].toUpperCase() + name.substring(1);
    name += 'Template';

    return buildStep.readAsString(buildStep.inputId).then<void>((source) {
      final nodes = Parser(environment).parse(source, path: inputId.path);
      final generator = TemplateBuilder(name);
      final code = formatter.format(generator.visit(nodes));
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), code);
    });
  }
}

class Frame {}

class TemplateBuilder extends Visitor<Frame, String> {
  TemplateBuilder(this.name);

  final String name;

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
}
