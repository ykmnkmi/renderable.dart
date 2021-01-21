import 'package:renderable/jinja.dart';

void main() {
  final environment = Environment();
  final template = environment.fromString('{{ {} is sequence }}');
  print(template.nodes);
  print(template.render());
}
