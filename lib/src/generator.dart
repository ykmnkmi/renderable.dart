import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'ast.dart';
import 'template.dart';

class GeneratedTemplate<C> implements Template<C> {
  final String path;

  const GeneratedTemplate(this.path);

  @override
  int get hashCode => runtimeType.hashCode ^ path.hashCode;

  @override
  List<Node> get nodes {
    // TODO: add error message
    throw UnsupportedError('');
  }

  @override
  bool operator ==(Object other) => other is GeneratedTemplate && path == other.path;

  @override
  String render([C context]) {
    // TODO: add error message
    throw UnsupportedError('');
  }
}

class TemplateGenerator extends Generator {
  final TypeChecker checker = TypeChecker.fromRuntime(GeneratedTemplate);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    library.allElements.forEach((Element element) {
      DartObject annotation = checker.firstAnnotationOf(element);

      if (annotation != null) {
        String path = annotation.getField('path').toStringValue();
        print('${element.name} - $path');
      }
    });

    return '// here must be templates and extensions';
  }
}
