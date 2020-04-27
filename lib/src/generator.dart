import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

import 'ast.dart';
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
  Iterable<Node> astNodes = const Parser().parse(template);
  return RendererCodeGenerator(buffer).visit(astNodes, clazz);
}

class RendererCodeGenerator implements Visitor<String, void> {
  final StringBuffer buffer;

  const RendererCodeGenerator(this.buffer);

  String visit(Iterable<Node> nodes, String clazz) {
    String clazzRenderer = '_${clazz}Renderer';
    String name = clazzRenderer.substring(1, 2).toLowerCase() + clazzRenderer.substring(2);

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

    if (nodes.any((Node node) => node is Text || node is Expression)) {
      buffer.write('=> \'');

      for (Node node in nodes) {
        node.accept(this, clazz);
      }

      buffer.write('\';');
      return;
    }

    throw UnimplementedError();
  }

  @override
  void visitName(Name node, String clazz) {
    buffer.write('\${context.${node.name}}');
  }

  @override
  void visitText(Text node, String clazz) {
    buffer.write(escape(node.text));
  }
}

class RenedererGenerator extends Generator {
  final TypeChecker checker = TypeChecker.fromRuntime(Generated);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    StringBuffer buffer = StringBuffer();

    String base = path.basename(buildStep.inputId.path);
    buffer..writeln('import \'package:renderable/renderable.dart\';')..writeln()..writeln('import \'$base\';');

    String root = path.dirname(buildStep.inputId.path);

    library.allElements.forEach((Element element) {
      DartObject annotation = checker.firstAnnotationOf(element);

      if (annotation != null) {
        DartObject templatePathField = annotation.getField('path');
        DartObject templateField = annotation.getField('template');

        String template;

        if (!templateField.isNull && templatePathField.isNull) {
          template = templateField.toStringValue();
        } else if (templateField.isNull && !templatePathField.isNull) {
          template = File(path.join(root, templatePathField.toStringValue())).readAsStringSync();
        } else {
          throw ArgumentError('one must be not null');
        }

        String name = element.name;
        String templateName = writeRendererFor(name, template, buffer);
        writeExtensionFor(name, templateName, buffer);
      }
    });

    return '$buffer';
  }
}
