import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'src/ast.dart';
import 'src/environment.dart';
import 'src/parser.dart';
import 'src/visitor.dart';

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder(options.config);
}

class HtmlTemplateBuilder extends Builder {
  HtmlTemplateBuilder([Map<String, Object> config = const <String, Object>{}]) : formatter = DartFormatter() {
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
        commentStart: commentStart,
        commentEnd: commentEnd,
        expressionStart: expressionStart,
        expressionEnd: expressionEnd,
        statementStart: statementStart,
        statementEnd: statementEnd);
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
      final node = Parser(environment).parse(source, path: inputId.path);
      final builder = TemplateBuilder(name, buffer);
      builder.visit(node);
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), formatter.format(buffer.toString()));
    });
  }
}

class TemplateBuilder extends Visitor {
  TemplateBuilder(this.name, this.buffer)
      : body = StringBuffer(),
        texts = <String>[],
        names = <String>{},
        accepted = false;

  final String name;

  final StringBuffer buffer;

  final StringBuffer body;

  final List<String> texts;

  final Set<String> names;

  bool accepted;

  @override
  void visit(Node node) {
    if (accepted) {
      // TODO: do something ...
      throw Exception('why!');
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
      buffer.writeAll(names.map<String>((name) => 'Object $name'), ', ');
      buffer.write('}');
    }

    buffer.write(') {');
    buffer.writeln('final buffer = StringBuffer();');
    buffer.write(body);
    buffer.writeln('return buffer.toString();');
    buffer.writeln('}');

    for (var i = 0; i < texts.length; i++) {
      buffer.writeln('static const String _t$i = ${wrapString(texts[i])};');
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
  void visitInterpolation(Interpolation node) {
    visitAll(node.children);
  }

  @override
  void visitIf(IfStatement node) {
    body.writeln();

    final entries = node.pairs.entries.toList();
    final first = entries.removeAt(0);

    writeIf(first.key, first.value);

    for (final entry in entries) {
      writeIf(entry.key, entry.value);
    }

    if (node.orElse != null) {
      body.writeln('else {');
      node.orElse.accept(this);
      body.writeln('}');
    }

    body.writeln();
  }

  @override
  void visitText(Text node) {
    var id = texts.indexOf(node.text);

    if (id == -1) {
      id = texts.length;
      texts.add(node.text);
    }

    body.writeln('buffer.write(_t$id);');
  }

  @override
  void visitVariable(Variable node) {
    names.add(node.name);
    body.writeln('buffer.write(${node.name});');
  }

  String wrapString(String value) {
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
  }void writeIf(Test check, Node node, [bool isElif = false]) {
    if (isElif) {
      body.write('else ');
    }

    body.write('if (');

    // TODO: replace with test
    if (check is Variable) {
      body.write(check.name + ' != null');
    } else {
      body.write(false);
    }

    body.writeln(') {');
    node.accept(this);
    body.writeln('}');
  }
}
