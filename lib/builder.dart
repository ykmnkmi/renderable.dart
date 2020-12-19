// ignore_for_file: import_of_legacy_library_into_null_safe
import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'src/configuration.dart';
import 'src/defaults.dart' as defaults;
import 'src/nodes.dart';
import 'src/parser.dart';
import 'src/utils.dart';
import 'src/visitor.dart';

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder(options.config);
}

class HtmlTemplateBuilder extends Builder {
  HtmlTemplateBuilder(Map<String, Object?> config) : formatter = DartFormatter() {
    environment = Configuration(
      commentBegin: config['comment_begin'] as String? ?? defaults.commentBegin,
      commentEnd: config['comment_end'] as String? ?? defaults.commentEnd,
      variableBegin: config['variable_begin'] as String? ?? defaults.variableBegin,
      variableEnd: config['variable_end'] as String? ?? defaults.variableEnd,
      blockBegin: config['block_begin'] as String? ?? defaults.blockBegin,
      blockEnd: config['block_end'] as String? ?? defaults.blockEnd,
    );
  }

  final DartFormatter formatter;

  late Configuration environment;

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
      final buffer = StringBuffer();
      TemplateBuilder(name, buffer, Parser(environment).parse(source, path: inputId.path));
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), formatter.format(buffer.toString()));
    });
  }
}

class TemplateBuilder extends Visitor<dynamic> {
  TemplateBuilder(this.name, this.templateBuffer, List<Node> nodes)
      : bodyBuffers = <StringBuffer>[],
        imports = <String>{'import \'package:renderable/core.dart\';'},
        names = <Name>{} {
    pushBodyBuffer();

    for (final node in nodes) {
      if (node is Data || node is Expression) {
        bodyBuffer.write('buffer.write(');
        node.accept(this);
        bodyBuffer.writeln(');');
      } else {
        throw 'implement statements: $node';
      }
    }

    final template = popBodyBuffer().toString();

    final imports = this.imports.toList();
    imports.sort();
    imports.forEach(templateBuffer.writeln);

    templateBuffer.writeln();

    templateBuffer.writeln('class $name implements Renderable {');
    templateBuffer.writeln('const $name();');
    templateBuffer.writeln();

    templateBuffer.write('String render(');

    if (names.isNotEmpty) {
      templateBuffer.write('{');
      templateBuffer.writeAll(names.map<String>((name) => '${name.type} ${name.name}'), ', ');
      templateBuffer.write('}');
    }

    templateBuffer.write(') {');
    templateBuffer.writeln('final buffer = StringBuffer();');
    templateBuffer.write(template);
    templateBuffer.writeln('return buffer.toString();');
    templateBuffer.writeln('}');

    templateBuffer.writeln('}');
  }

  final String name;

  final StringBuffer templateBuffer;

  final List<StringBuffer> bodyBuffers;

  final Set<String> imports;

  final Set<Name> names;

  StringBuffer get bodyBuffer {
    return bodyBuffers.last;
  }

  StringBuffer popBodyBuffer() {
    return bodyBuffers.removeLast();
  }

  void pushBodyBuffer([String content = '']) {
    bodyBuffers.add(StringBuffer(content));
  }

  @override
  void visitAttribute(Attribute node) {
    node.expression.accept(this);
    bodyBuffer.write('.');
    bodyBuffer.write(node.attribute);
  }

  @override
  void visitBinary(Binary node) {
    throw 'implement visitBinary';
  }

  @override
  void visitCall(Call node) {
    node.expression.accept(this);
    writeCalling(node.arguments, node.keywordArguments, node.dArguments, node.dKeywordArguments);
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  void visitConcat(Concat node) {
    pushBodyBuffer();

    for (final expression in node.expressions) {
      if (expression is Name) {
        bodyBuffer.write(r'$');
        expression.accept(this);
      } else {
        bodyBuffer.write(r'${');
        expression.accept(this);
        bodyBuffer.write('}');
      }
    }

    final template = popBodyBuffer().toString();
    var quote = '\'';

    if (template.contains('\n') || template.contains('\r\n')) {
      quote *= 3;
    }

    bodyBuffer.write('$quote$template$quote');
  }

  @override
  void visitCondition(Condition node) {
    throw 'implement visitCondition';
  }

  @override
  void visitConstant(Constant<dynamic> node) {
    bodyBuffer.write(represent(node.value));
  }

  @override
  void visitData(Data node) {
    bodyBuffer.write(wrapData(node.data));
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    writeCollection(node.pairs, '{', '}');
  }

  @override
  void visitFilter(Filter node) {
    imports.add('import \'package:renderable/filters.dart\' as filters;');
    bodyBuffer.write('filters.${node.name}');
    writeCalling(<Expression>[node.expression, ...node.arguments], node.keywordArguments, node.dArguments, node.dKeywordArguments);
  }

  @override
  void visitIf(If node) {
    throw 'implement visitIf';
  }

  @override
  void visitItem(Item node) {
    node.expression.accept(this);
    bodyBuffer.write('[');
    node.key.accept(this);
    bodyBuffer.write('[');
  }

  @override
  void visitKeyword(Keyword node) {
    bodyBuffer.write(node.key);
    bodyBuffer.write(': ');
    node.value.accept(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    writeCollection(node.nodes);
  }

  @override
  void visitName(Name node) {
    names.add(node);
    bodyBuffer.write(node.name);
  }

  @override
  void visitOperand(Operand node) {
    throw 'implement visitOperand';
  }

  @override
  void visitOutput(Output node) {
    for (final node in node.nodes) {
      if (node is Data || node is Expression) {
        bodyBuffer.write('buffer.write(');
        node.accept(this);
        bodyBuffer.writeln(');');
      } else {
        throw 'implement statements: $node';
      }
    }
  }

  @override
  void visitPair(Pair node) {
    node.key.accept(this);
    bodyBuffer.write(': ');
    node.value.accept(this);
  }

  @override
  void visitSlice(Slice node) {
    bodyBuffer.write('slice(');
    node.expression.accept(this);
    bodyBuffer.write(', ');
    node.start.accept(this);

    final stop = node.stop;

    if (stop != null) {
      bodyBuffer.write(', ');
      stop.accept(this);
    }

    final step = node.step;

    if (step != null) {
      bodyBuffer.write(', ');
      step.accept(this);
    }

    bodyBuffer.write(')');
  }

  @override
  void visitTest(Test node) {
    imports.add('import \'package:renderable/tests.dart\' as tests;');
    bodyBuffer.write('tests.${node.name}');
    writeCalling(<Expression>[node.expression, ...node.arguments], node.keywordArguments, node.dArguments, node.dKeywordArguments);
  }

  @override
  void visitTupleLiteral(TupleLiteral node) {
    writeCollection(node.nodes);
  }

  @override
  void visitUnary(Unary node) {
    bodyBuffer.write(node.operator);
    node.expression.accept(this);
  }

  @protected
  void writeCalling(List<Expression> arguments, List<Keyword> keywordArguments, [Expression? dArguments, Expression? dKeywordArguments]) {
    bodyBuffer.write('(');

    for (final param in arguments.cast<Node>().followedBy(keywordArguments.cast<Node>())) {
      bodyBuffer.write(', ');
      param.accept(this);
    }

    // TODO: add dynamic arguments

    bodyBuffer.write(')');
  }

  @protected
  void writeCollection(List<Node> nodes, [String open = '[', String close = ']']) {
    bodyBuffer.write(open);

    for (final node in nodes.take(nodes.length - 1)) {
      node.accept(this);
      bodyBuffer.write(', ');
    }

    nodes.last.accept(this);
    bodyBuffer.write(close);
  }

  @protected
  static String wrapData(String value) {
    final quote = value.contains('\n') || value.contains('\r\n') ? "\'\'\'" : '\'';
    value = value.replaceAll('\'', '\\\'');
    return '$quote$value$quote';
  }
}
