import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'src/nodes.dart';
import 'src/configuration.dart';
import 'src/parser.dart';
import 'src/utils.dart';
import 'src/visitor.dart';

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder(options.config);
}

class HtmlTemplateBuilder extends Builder {
  HtmlTemplateBuilder([Map<String, Object> config]) : formatter = DartFormatter() {
    String commentStart;
    String commentEnd;

    if (config.containsKey('comment_start')) {
      commentStart = config['comment_start'] as String;
    } else {
      commentStart = '{#';
    }

    if (config.containsKey('comment_end')) {
      commentEnd = config['comment_end'] as String;
    } else {
      commentEnd = '#}';
    }

    String expressionStart, expressionEnd;

    if (config.containsKey('expression_start')) {
      expressionStart = config['expression_start'] as String;
    } else {
      expressionStart = '{{';
    }

    if (config.containsKey('expression_end')) {
      expressionEnd = config['expression_end'] as String;
    } else {
      expressionEnd = '}}';
    }

    String statementStart;
    String statementEnd;

    if (config.containsKey('statement_start')) {
      statementStart = config['statement_start'] as String;
    } else {
      statementStart = '{%';
    }

    if (config.containsKey('statement_end')) {
      statementEnd = config['statement_end'] as String;
    } else {
      statementEnd = '%}';
    }

    environment = Configuration(
        commentBegin: commentStart,
        commentEnd: commentEnd,
        variableBegin: expressionStart,
        variableEnd: expressionEnd,
        blockBegin: statementStart,
        blockEnd: statementEnd);
  }

  final DartFormatter formatter;

  Configuration environment;

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
      var buffer = StringBuffer();
      TemplateBuilder(name, buffer, Parser(environment).parse(source, path: inputId.path));
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), formatter.format(buffer.toString()));
    });
  }
}

class TemplateBuilder extends Visitor {
  TemplateBuilder(this.name, this.templateBuffer, Node body)
      : bodyBuffers = <StringBuffer>[],
        names = <Name>{} {
    var isExpression = false;
    pushBodyBuffer();

    if (body is Expression) {
      isExpression = true;
      body.accept(this);
    } else if (body is Output) {
      for (final child in body.nodes) {
        if (child is Expression) {
          bodyBuffer.write('buffer.write(');
          child.accept(this);
          bodyBuffer.writeln(');');
        } else {
          throw 'implment statements';
        }
      }
    }

    var template = popBodyBuffer().toString();

    templateBuffer.writeln('import \'package:renderable/renderable.dart\';');
    templateBuffer.writeln();

    templateBuffer.writeln('class $name implements Template {');
    templateBuffer.writeln('const $name();');
    templateBuffer.writeln();

    templateBuffer.write('String render(');

    if (names.isNotEmpty) {
      templateBuffer.write('{');
      templateBuffer.writeAll(names.map<String>((name) => '${name.type} ${name.name}'), ', ');
      templateBuffer.write('}');
    }

    templateBuffer.write(') {');

    if (isExpression) {
      templateBuffer.write('return ');
      templateBuffer.write(template);
      templateBuffer.writeln(';');
    } else {
      templateBuffer.writeln('final buffer = StringBuffer();');
      templateBuffer.write(template);
      templateBuffer.writeln('return buffer.toString();');
    }

    templateBuffer.writeln('}');
    templateBuffer.writeln('}');
  }

  final String name;

  final StringBuffer templateBuffer;

  final List<StringBuffer> bodyBuffers;

  final Set<Name> names;

  StringBuffer get bodyBuffer {
    return bodyBuffers.last;
  }

  void pushBodyBuffer() {
    bodyBuffers.add(StringBuffer());
  }

  StringBuffer popBodyBuffer() {
    return bodyBuffers.removeLast();
  }

  @override
  void visitAll(Iterable<Node> nodes) {
    for (final node in nodes) {
      node.accept(this);
    }
  }

  @override
  void visitAttribute(Attribute node) {
    node.expression.accept(this);
    bodyBuffer.write('.');
    bodyBuffer.write(node.attribute);
  }

  @override
  void visitCall(Call node) {
    throw 'implement visitCall';
  }

  @override
  void visitConcat(Concat node) {
    pushBodyBuffer();

    for (final expression in node.expressions) {
      if (expression is Name) {
        bodyBuffer.write(r'$');
        expression.accept(this);
      } else if (expression is! Data) {
        bodyBuffer.write(r'${');
        expression.accept(this);
        bodyBuffer.write('}');
      } else {
        bodyBuffer.write((expression as Data).data.replaceAll('\'', '\\\''));
      }
    }

    var template = popBodyBuffer().toString();
    var quote = '\'';

    if (template.contains('\n') || template.contains('\r\n')) {
      quote *= 3;
    }

    bodyBuffer.write(quote + template + quote);
  }

  @override
  void visitConstant(Constant<Object> node) {
    bodyBuffer.write(represent(node.value));
  }

  @override
  void visitData(Data node) {
    bodyBuffer.write(_wrapData(node.data));
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    bodyBuffer.write('{');

    for (final item in node.pairs) {
      item.accept(this);

      if (item != node.pairs.last) {
        bodyBuffer.write(', ');
      }
    }

    bodyBuffer.write('}');
  }

  @override
  void visitFilter(Filter node) {
    bodyBuffer.write(node.name);
    bodyBuffer.write('(');
    node.expression.accept(this);

    for (var param in node.arguments.cast<Node>().followedBy(node.keywordArguments.cast<Node>())) {
      bodyBuffer.write(', ');
      param.accept(this);
    }

    bodyBuffer.write(')');
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
    bodyBuffer.write('[');

    for (final item in node.values) {
      item.accept(this);

      if (item != node.values.last) {
        bodyBuffer.write(', ');
      }
    }

    bodyBuffer.write(']');
  }

  @override
  void visitName(Name node) {
    names.add(node);
    bodyBuffer.write(node.name);
  }

  @override
  void visitOutput(Output node) {
    visitAll(node.nodes);
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

    if (node.stop != null) {
      bodyBuffer.write(', ');
      node.stop.accept(this);
    }

    if (node.step != null) {
      bodyBuffer.write(', ');
      node.step.accept(this);
    }

    bodyBuffer.write(')');
  }

  @override
  void visitTest(Test node) {
    throw Exception();
  }

  @override
  void visitTupleLiteral(TupleLiteral node) {
    throw Exception();
  }

  @override
  void visitUnary(Unary node) {
    bodyBuffer.write(node.operator);
    node.expression.accept(this);
  }

  static String _wrapData(String value) {
    var quote = value.contains(r'\n') || value.contains(r'\r\n') ? '\'' : "\'\'\'";
    value = value.replaceAll('\'', '\\\'');
    return quote + value + quote;
  }

  @override
  void visitBinary(Binary node) {
    throw 'implement visitBinary';
  }

  @override
  void visitCompare(Compare node) {
    throw 'implement visitCompare';
  }

  @override
  void visitCondition(Condition node) {
    throw 'implement visitCondition';
  }

  @override
  void visitOperand(Operand node) {
    throw 'implement visitOperand';
  }
}
