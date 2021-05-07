import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'context.dart';
import 'enirvonment.dart';
import 'exceptions.dart';
import 'optimizer.dart';

abstract class Loader {
  String getSource(String template) {
    throw TemplateNotFound(name: template);
  }

  bool get hasSourceAccess {
    return true;
  }

  List<String> listSources() {
    throw UnsupportedError('this loader cannot iterate over all templates');
  }

  Template load(Environment environment, String name);
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

    throw TemplateNotFound(name: template);
  }

  @override
  List<String> listSources() {
    return mapping.keys.toList();
  }

  @override
  Template load(Environment environment, String name) {
    final source = getSource(name);
    return environment.fromString(source);
  }
}

class FileSystemLoader extends Loader {
  FileSystemLoader({
    String path = 'templates',
    List<String>? paths,
    this.followLinks = true,
    this.extensions = const <String>{'html'},
    this.encoding = utf8,
  }) : paths = paths ?? <String>[path];

  final List<String> paths;

  final bool followLinks;

  final Set<String> extensions;

  final Encoding encoding;

  StreamSubscription<ProcessSignal>? subscription;

  List<StreamSubscription<void>>? subscriptions;

  File? findFile(String path) {
    final pieces = path.split('/');

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
      throw TemplateNotFound(name: template);
    }

    return file.readAsStringSync(encoding: encoding);
  }

  @override
  List<String> listSources() {
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
  Template load(Environment environment, String name) {
    final file = findFile(name);

    if (file == null) {
      throw TemplateNotFound(name: name);
    }

    var source = file.readAsStringSync(encoding: encoding);
    var nodes = environment.parse(source, path: name);

    for (final modifier in environment.modifiers) {
      for (final node in nodes) {
        modifier(node);
      }
    }

    const optimizer = Optimizer();
    final template = Template.parsed(environment, nodes, path: name);

    if (environment.optimized) {
      template.accept(optimizer, Context(environment));
    }

    return template;
  }

  @override
  String toString() {
    return 'FileSystemLoader($paths)';
  }
}
