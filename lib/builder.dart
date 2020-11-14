import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'src/nodes.dart';
import 'src/environment.dart';
import 'src/parser.dart';
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

    environment = Environment(
        commentBegin: commentStart,
        commentEnd: commentEnd,
        variableBegin: expressionStart,
        variableEnd: expressionEnd,
        blockBegin: statementStart,
        blockEnd: statementEnd);
  }

  final DartFormatter formatter;

  Environment environment;

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

    final buffer = StringBuffer();
    return buildStep.readAsString(buildStep.inputId).then<void>((source) {
      TemplateBuilder(name, buffer).visit(Parser(environment).parse(source, path: inputId.path));
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), formatter.format(buffer.toString()));
    });
  }
}

class TemplateBuilder extends Visitor {
  TemplateBuilder(this.name, this.buffer)
      : body = StringBuffer(),
        texts = <String>[],
        names = <Name>{},
        accepted = false;

  final String name;

  final StringBuffer buffer;

  final StringBuffer body;

  final List<String> texts;

  final Set<Name> names;

  bool accepted;

  void _writeIf(Test check, Node node, [bool isElif = false]) {
    if (isElif) {
      body.write('else ');
    }

    body.write('if (');
    check.accept(this);
    body.writeln(') {');
    node.accept(this);
    body.writeln('}');
  }

  String _wrapString(String value) {
    final multiline = value.contains(r'\n') || value.contains(r'\r\n');
    final hasSingleQuote = value.contains(r"'");
    final hasDoubleQuote = value.contains(r'"');
    var wrapper = hasSingleQuote ? '"' : "'";

    if (hasSingleQuote && hasDoubleQuote) {
      value = value.replaceAll(r'"', r'\"');
    }

    if (multiline) {
      wrapper = wrapper * 3;
    }

    return wrapper + value + wrapper;
  }

  @override
  void visit(Node node) {
    if (accepted) {
      throw StateError('why!');
    }

    accepted = true;
    node.accept(this);

    buffer.writeln('import \'package:renderable/renderable.dart\';');
    buffer.writeln();

    buffer.writeln('class $name implements Template {');
    buffer.writeln('const $name();');
    buffer.writeln();

    buffer.write('String render(');

    if (names.isNotEmpty) {
      buffer.write('{');
      buffer.writeAll(names.map<String>((name) => '${name.type} ${name.name}'), ', ');
      buffer.write('}');
    }

    buffer.write(') {');
    buffer.writeln('final buffer = StringBuffer();');
    buffer.write(body);
    buffer.writeln('return buffer.toString();');
    buffer.writeln('}');

    for (var i = 0; i < texts.length; i++) {
      buffer.writeln('static const String _t$i = ${_wrapString(texts[i])};');
      buffer.writeln();
    }

    buffer.writeln('}');
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
    body.write('.');
    body.write(node.attribute);
  }

  @override
  void visitData(Data node) {
    var id = texts.indexOf(node.data);

    if (id == -1) {
      id = texts.length;
      texts.add(node.data);
    }

    body.write('_t$id');
  }

  @override
  void visitDictLiteral(DictLiteral node) {
    body.write('{');

    for (final item in node.items) {
      item.accept(this);

      if (item != node.items.last) {
        body.write(', ');
      }
    }

    body.write('}');
  }

  @override
  void visitIf(If node) {
    body.writeln();

    final entries = node.pairs.entries.toList();
    final first = entries.removeAt(0);

    _writeIf(first.key, first.value);

    for (final entry in entries) {
      _writeIf(entry.key, entry.value);
    }

    if (node.orElse != null) {
      body.writeln('else {');
      node.orElse.accept(this);
      body.writeln('}');
    }

    body.writeln();
  }

  @override
  void visitItem(Item node) {
    node.expression.accept(this);
    body.write('[');
    node.key.accept(this);
    body.write('[');
  }

  @override
  void visitListLiteral(ListLiteral node) {
    body.write('[');

    for (final item in node.items) {
      item.accept(this);

      if (item != node.items.last) {
        body.write(', ');
      }
    }

    body.write(']');
  }

  @override
  void visitLiteral(Literal node) {
    throw UnimplementedError();
  }

  @override
  void visitName(Name node) {
    names.add(node);
    body.write(node.name);
  }

  @override
  void visitOutput(Output node) {
    visitAll(node.items);
  }

  @override
  void visitPair(Pair node) {
    node.key.accept(this);
    body.write(': ');
    node.value.accept(this);
  }

  @override
  void visitSlice(Slice node) {
    body.write('slice(');
    node.expression.accept(this);
    body.write(', ');
    node.start.accept(this);

    if (node.stop != null) {
      body.write(', ');
      node.stop.accept(this);
    }

    if (node.step != null) {
      body.write(', ');
      node.step.accept(this);
    }

    body.write(')');
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
    throw Exception();
  }
}
