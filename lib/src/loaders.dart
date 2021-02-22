import 'enirvonment.dart';
import 'exceptions.dart';

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

  Template load(Environment environment, String name) {
    final source = getSource(name);
    return environment.fromString(source);
  }
}

class MapLoader extends Loader {
  MapLoader(this.mapping);

  final Map<String, String> mapping;

  @override
  bool get hasSourceAccess {
    return false;
  }

  @override
  List<String> listSources() {
    return mapping.keys.toList();
  }

  @override
  String getSource(String template) {
    if (mapping.containsKey(template)) {
      return mapping[template]!;
    }

    throw TemplateNotFound(name: template);
  }
}
