import 'package:renderable/jinja.dart';

void main() {
  final environment = Environment(autoEscape: true);
  final template = environment.fromString('{{ ["<foo>", "<span>foo</span>" | safe] | join }}');
  print(template.nodes);
  print(template.render());
}
