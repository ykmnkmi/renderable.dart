import 'dart:async';

import 'package:build/build.dart';
import 'package:path/path.dart' as path;

Builder htmlTemplateBuilder(BuilderOptions options) {
  return HtmlTemplateBuilder();
}

class HtmlTemplateBuilder extends Builder {
  HtmlTemplateBuilder();

  @override
  Map<String, List<String>> get buildExtensions {
    return <String, List<String>>{
      '.html': ['.html.dart'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final buffer = StringBuffer();

    var name = path.basenameWithoutExtension(inputId.path);
    name = name[0].toUpperCase() + name.substring(1);
    name += 'Template';
    
    buffer.writeln('import \'package:renderable/renderable.dart\';');
    buffer.writeln();
    buffer.writeln('class $name implements Template {}');

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.html.dart'),
      buffer.toString(),
    );
  }
}
