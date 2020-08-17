import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

import 'ast.dart';
import 'environment.dart';
import 'parser.dart';
import 'util.dart';
import 'visitor.dart';

String getRendererName(String clazzRenderer) {
  return clazzRenderer.substring(1, 2).toLowerCase() + clazzRenderer.substring(2);
}

void writeExtensionFor(StringBuffer buffer, String clazz) {
  final clazzRenderer = '_${clazz}Renderer';
  final name = getRendererName(clazzRenderer);
  buffer.writeln('extension ${clazz}Renderer on $clazz {');
  buffer.writeln('String render() => ${name}.render(this);');
  buffer.writeln('}');
  buffer.writeln();
}

class RendererGenerator extends Visitor<String, void> {
  const RendererGenerator(this.buffer);

  final StringBuffer buffer;

  @override
  void visitText(Text text, [String clazz]) {
    buffer.write('return ${repr(text.text)};');
  }

  @override
  void visitVariable(Variable variable, [String clazz]) {
    buffer.write('\${context.${variable.name}}');
  }

  @override
  void visitInterpolation(Interpolation interpolation, [String clazz]) {
    // TODO: implement visitInterpolation
  }

  @override
  void visitIf(IfStatement ifStatement, [String clazz]) {
    // TODO: implement visitIf
  }

  @override
  void visitAll(Iterable<Node> nodes, [String clazz]) {
    for (final node in nodes) {
      node.accept(this, clazz);
    }
  }

  @override
  void visit(Node node, [String context]) {}
}

class RenderableGenerator extends GeneratorForAnnotation<Renderable> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final templatePathField = annotation.read('path');
    final templateField = annotation.read('template');
    final root = path.dirname(buildStep.inputId.path);

    String template;

    if (!templateField.isNull && templatePathField.isNull) {
      template = templateField.stringValue;
    } else if (templateField.isNull && !templatePathField.isNull) {
      template = File(path.join(root, templatePathField.stringValue)).readAsStringSync();
    } else {
      throw ArgumentError('one must be not null');
    }

    final buffer = StringBuffer();
    final name = element.name;
    final environment = Environment();
    final node = Parser(environment).parse(template);
    final clazzRenderer = '_${name}Renderer';
    final clazz = getRendererName(clazzRenderer);
    buffer.write('const $clazzRenderer ');
    buffer.write(name);
    buffer.writeln(' = $clazzRenderer();');
    buffer.writeln('class $clazzRenderer implements Renderable<$clazz> {');
    buffer.writeln('const $clazzRenderer();');
    buffer.writeln();
    RendererGenerator(buffer).visit(node);
    buffer.writeln('}');
    buffer.writeln();
    writeExtensionFor(buffer, name);
    return buffer.toString();
  }
}
