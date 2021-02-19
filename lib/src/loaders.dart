import 'enirvonment.dart';

abstract class Loader {
  String getSource(String path) {
    throw Exception('template not found: $path');
  }

  bool get hasSourceAccess {
    return true;
  }

  List<String> listSources() {
    throw UnsupportedError('this loader cannot iterate over all templates');
  }

  Template load(Environment environment, String name) {
    final source = getSource(name);
    final nodes = environment.parse(source);
    return Template.parsed(environment, nodes);
  }
}
