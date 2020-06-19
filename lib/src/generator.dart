import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

import 'ast.dart';
import 'environment.dart';
import 'interface.dart';
import 'parser.dart';
import 'visitor.dart';

void writeExtensionFor(StringBuffer buffer, String clazz) {
  final clazzRenderer = '_${clazz}Renderer';
  final name = getRendererName(clazzRenderer);
  buffer
    ..writeln('extension ${clazz}Renderer on $clazz {')
    ..writeln('String render() => ${name}.render(this);')
    ..writeln('}')
    ..writeln();
}

class RenderableGenerator extends GeneratorForAnnotation<Renderable<Object>> {
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
    RendererGenerator(buffer, name, node);
    writeExtensionFor(buffer, name);
    return buffer.toString();
  }
}

class RendererGenerator extends Visitor<String, void> {
  final StringBuffer buffer;

  RendererGenerator(this.buffer, String clazz, Node node) {
    final clazzRenderer = '_${clazz}Renderer';
    final name = getRendererName(clazz);
    buffer
      ..write('const $clazzRenderer ')
      ..write(name)
      ..writeln(' = $clazzRenderer();')
      ..writeln('class $clazzRenderer implements Renderable<$clazz> {')
      ..writeln('const $clazzRenderer();')
      ..writeln();

    visit(node, clazz);

    buffer..writeln('}')..writeln();
  }

  @override
  void visitAll(Iterable<Node> nodes, [String clazz]) {
    for (var node in nodes) {
      node.accept(this, clazz);
    }
  }

  @override
  void visitIf(IfStatement ifStatement, [String clazz]) {
    // TODO: implement visitIf
  }

  @override
  void visitInterpolation(Interpolation interpolation, [String clazz]) {
    // TODO: implement visitInterpolation
  }

  @override
  void visitText(Text text, [String clazz]) {
    buffer.write(text.text);
  }

  @override
  void visitVariable(Variable variable, [String clazz]) {
    buffer.write('\${context.${variable.name}}');
  }
}

String getRendererName(String clazzRenderer) {
  return clazzRenderer.substring(1, 2).toLowerCase() + clazzRenderer.substring(2);
}
