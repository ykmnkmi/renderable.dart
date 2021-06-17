import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'enirvonment.dart';
import 'exceptions.dart';

abstract class Loader {
  String getSource(String template) {
    if (hasSourceAccess) {
      throw UnsupportedError('this loader cannot provide access to the source');
    }

    throw TemplateNotFound(template: template);
  }

  bool get hasSourceAccess {
    return true;
  }

  List<String> listTemplates() {
    throw UnsupportedError('this loader cannot iterate over all templates');
  }

  Template load(Environment environment, String template);
}

class MapLoader extends Loader {
  MapLoader(this.mapping);

  final Map<String, String> mapping;

  @override
  bool get hasSourceAccess {
    return false;
  }

  @override
  String getSource(String template) {
    if (mapping.containsKey(template)) {
      return mapping[template]!;
    }

    throw TemplateNotFound(template: template);
  }

  @override
  List<String> listTemplates() {
    return mapping.keys.toList();
  }

  @override
  Template load(Environment environment, String template) {
    final source = getSource(template);
    return environment.fromString(source, path: template);
  }
}

class FileSystemLoader extends Loader {
  FileSystemLoader({
    String? path,
    List<String>? paths,
    this.followLinks = true,
    this.extensions = const <String>{'html'},
    this.encoding = utf8,
  }) : paths = paths ?? <String>[path ?? 'templates'];

  final List<String> paths;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  File? findFile(String template) {
    final pieces = template.split('/');

    for (final path in paths) {
      final templatePath = p.joinAll(<String>[path, ...pieces]);
      final templateFile = File(templatePath);

      if (templateFile.existsSync()) {
        return templateFile;
      }
    }
  }

  bool isTemplate(String path, [String? from]) {
    final template = p.relative(path, from: from);
    var ext = p.extension(template);

    if (ext.startsWith('.')) {
      ext = ext.substring(1);
    }

    return extensions.contains(ext) && FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
  }

  @override
  String getSource(String template) {
    final file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @override
  List<String> listTemplates() {
    final found = <String>[];

    for (final path in paths) {
      final directory = Directory(path);

      if (directory.existsSync()) {
        final entities = directory.listSync(recursive: true, followLinks: followLinks);

        for (final entity in entities) {
          if (isTemplate(entity.path, path)) {
            final template = p.relative(entity.path, from: path).replaceAll(Platform.pathSeparator, '/');

            if (!found.contains(template)) {
              found.add(template);
            }
          }
        }
      }
    }

    found.sort();
    return found;
  }

  @override
  Template load(Environment environment, String template) {
    final file = findFile(template);

    if (file == null) {
      throw TemplateNotFound(template: template);
    }

    final source = file.readAsStringSync(encoding: encoding);
    return environment.fromString(source, path: template);
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
}
