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
    throw UnimplementedError('implement visit');
  }

  @override
  String visitAttribute(Attribute node, [Frame? frame]) {
    throw UnimplementedError('implement visitAttribute');
  }

  @override
  String visitBinary(Binary node, [Frame? frame]) {
    throw UnimplementedError('implement visitBinary');
  }

  @override
  String visitCall(Call node, [Frame? frame]) {
    throw UnimplementedError('implement visitCall');
  }

  @override
  String visitCompare(Compare node, [Frame? frame]) {
    throw UnimplementedError('implement visitCompare');
  }

  @override
  String visitConcat(Concat node, [Frame? frame]) {
    throw UnimplementedError('implement visitConcat');
  }

  @override
  String visitCondition(Condition node, [Frame? frame]) {
    throw UnimplementedError('implement visitCondition');
  }

  @override
  String visitConstant(Constant<Object?> node, [Frame? frame]) {
    throw UnimplementedError('implement visitConstant');
  }

  @override
  String visitData(Data node, [Frame? frame]) {
    throw UnimplementedError('implement visitData');
  }

  @override
  String visitDictLiteral(DictLiteral node, [Frame? frame]) {
    throw UnimplementedError('implement visitDictLiteral');
  }

  @override
  String visitFilter(Filter node, [Frame? frame]) {
    throw UnimplementedError('implement visitFilter');
  }

  @override
  String visitIf(If node, [Frame? frame]) {
    throw UnimplementedError('implement visitIf');
  }

  @override
  String visitItem(Item node, [Frame? frame]) {
    throw UnimplementedError('implement visitItem');
  }

  @override
  String visitKeyword(Keyword node, [Frame? frame]) {
    throw UnimplementedError('implement visitKeyword');
  }

  @override
  String visitListLiteral(ListLiteral node, [Frame? frame]) {
    throw UnimplementedError('implement visitListLiteral');
  }

  @override
  String visitName(Name node, [Frame? frame]) {
    throw UnimplementedError('implement visitName');
  }

  @override
  String visitOperand(Operand node, [Frame? frame]) {
    throw UnimplementedError('implement visitOperand');
  }

  @override
  String visitOutput(Output node, [Frame? frame]) {
    throw UnimplementedError('implement visitOutput');
  }

  @override
  String visitPair(Pair node, [Frame? frame]) {
    throw UnimplementedError('implement visitPair');
  }

  @override
  String visitSlice(Slice node, [Frame? frame]) {
    throw UnimplementedError('implement visitSlice');
  }

  @override
  String visitTest(Test node, [Frame? frame]) {
    throw UnimplementedError('implement visitTest');
  }

  @override
  String visitTupleLiteral(TupleLiteral node, [Frame? frame]) {
    throw UnimplementedError('implement visitTupleLiteral');
  }

  @override
  String visitUnary(Unary node, [Frame? frame]) {
    throw UnimplementedError('implement visitUnary');
  }
}
