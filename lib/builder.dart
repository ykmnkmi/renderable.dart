import 'dart:async';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;

import 'src/ast.dart';
import 'src/environment.dart';
import 'src/parser.dart';
import 'src/visitor.dart';

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder();
}

class HtmlTemplateBuilder extends Builder {
  HtmlTemplateBuilder() : formatter = DartFormatter();

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

    final buffer = StringBuffer();
    buffer.writeln('import \'package:renderable/renderable.dart\';');
    buffer.writeln();
    buffer.writeln('class $name implements Template {');
    buffer.writeln('const $name();');
    buffer.writeln();

    return buildStep.readAsString(buildStep.inputId).then<void>((source) {
      final environment = const Environment();
      final node = Parser(environment).parse(source, path: inputId.path);

      final context = TemplateBuilderContext(buffer);
      const TemplateBuilder().visit(node, context);

      print(node);

      context.build();

      buffer.writeln('}');
      buildStep.writeAsString(buildStep.inputId.changeExtension('.html.dart'), formatter.format(buffer.toString()));
    });
  }
}

abstract class NodeType {
  static const int string = 1 << 0;
  static const int varialble = 1 << 1;
}

class TemplateBuilderContext {
  TemplateBuilderContext(this.buffer)
      : ids = <String>[],
        types = <String, int>{},
        names = <String>{},
        statics = StringBuffer(),
        accepted = false,
        lastID = 0;

  final StringBuffer buffer;

  final List<String> ids;

  final Map<String, int> types;

  final Set<String> names;

  final StringBuffer statics;

  bool accepted;

  int lastID;

  void addVariable(String name) {
    names.add(name);
    ids.add(name);
    types[name] = NodeType.varialble;
  }

  void addText(String value) {
    final id = getID();
    ids.add(id);
    types[id] = NodeType.string;
    statics.writeln('static const String _s$id = ${wrapString(value)};');
    statics.writeln();
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
  }

  String getID() {
    final id = lastID.toString();
    ++lastID;
    return id;
  }

  void build() {
    final arguments = names.isNotEmpty ? ('{' + names.map((name) => 'Object $name,').join(' ') + '}') : '';
    buffer.writeln('String render($arguments) {');
    buffer.writeln('final buffer = StringBuffer();');

    for (final id in ids) {
      switch (types[id]) {
        case NodeType.string:
          buffer.writeln('buffer.write(_s$id);');
          break;
        case NodeType.varialble:
          buffer.writeln('buffer.write($id);');
          break;
      }
    }

    buffer.writeln('return buffer.toString();');
    buffer.writeln('}');

    buffer.write(statics);
  }
}

class TemplateBuilder extends Visitor<TemplateBuilderContext, void> {
  const TemplateBuilder();

  @override
  void visitText(Text text, [TemplateBuilderContext context]) {
    context.addText(text.text);
  }

  @override
  void visitVariable(Variable variable, [TemplateBuilderContext context]) {
    context.addVariable(variable.name);
  }

  @override
  void visitIf(IfStatement ifStatement, [TemplateBuilderContext context]) {}

  @override
  void visitInterpolation(Interpolation interpolation, [TemplateBuilderContext context]) {}

  @override
  void visitAll(Iterable<Node> nodes, [TemplateBuilderContext context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visit(Node node, [TemplateBuilderContext context]) {
    if (context.accepted) {
      // TODO: do something ...
      throw Exception('why!');
    }

    context.accepted = true;
    if (node is Interpolation) {
      visitAll(node.nodes, context);
    } else {
      node.accept(this, context);
    }
  }
}
