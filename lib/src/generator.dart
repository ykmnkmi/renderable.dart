import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

import 'ast.dart';
import 'env.dart';
import 'interface.dart';
import 'parser.dart';
import 'visitor.dart';

String escape(String text) => text.replaceAll('\$', '\\\$').replaceAll('\'', '\\\'');

void writeExtensionFor(String clazz, String templateName, StringBuffer buffer) {
  buffer
    ..writeln('extension ${clazz}Renderer on $clazz {')
    ..writeln('String render() => ${templateName}.render(this);')
    ..writeln('}')
    ..writeln();
}

String writeRendererFor(String clazz, String template, StringBuffer buffer) {
  final astNodes = const Parser(Environment.default_).parse(template);
  return RendererCodeGenerator(buffer).visit(astNodes, clazz);
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
    final templateName = writeRendererFor(name, template, buffer);
    writeExtensionFor(name, templateName, buffer);
    return buffer.toString();
  }
}

class RendererCodeGenerator implements Visitor<String, void> {
  final StringBuffer buffer;

  const RendererCodeGenerator(this.buffer);

  String visit(Iterable<Node> nodes, String clazz) {
    final clazzRenderer = '_${clazz}Renderer';
    final name = clazzRenderer.substring(1, 2).toLowerCase() + clazzRenderer.substring(2);

    buffer
      ..write('const $clazzRenderer ')
      ..write(name)
      ..writeln(' = $clazzRenderer();')
      ..writeln('class $clazzRenderer implements Renderable<$clazz> {')
      ..writeln('const $clazzRenderer();');
    visitAll(nodes, clazz);
    buffer..writeln('}')..writeln();
    return name;
  }

  @override
  void visitAll(Iterable<Node> nodes, String clazz) {
    nodes = nodes.toList(growable: false);

    buffer
      ..writeln()
      ..write('@override String render([$clazz context]) ');

    if (nodes.any((node) => node is Text || node is Expression)) {
      buffer.write('=> \'');

      for (var node in nodes) {
        node.accept(this, clazz);
      }

      buffer.write('\';');
      return;
    }

    throw UnimplementedError();
  }

  @override
  void visitVariable(Variable variable, String clazz) {
    buffer.write('\${context.${variable.name}}');
  }

  @override
  void visitText(Text text, String clazz) {
    buffer.write(escape(text.text));
  }
}