import 'package:renderable/jinja.dart';
import 'package:renderable/reflection.dart';

class Foo {
  dynamic operator [](dynamic key) {
    return key;
  }
}

void main() {
  final environment = Environment();
  final template = environment.fromString('{{ -1|foo }}');
  print(template.nodes);
  // print(render(template, foo: Foo()));
}
