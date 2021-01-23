import 'package:renderable/jinja.dart';

import 'dart:math';

void main() {
  final random = Random(0);
  final environment = Environment(random: random);
  final template = environment.fromString('{{ "123456789" | random }}');
  print(template.nodes);

  for (var i = 0; i < 10; i++) {
    print(template.render());
    print(template.render());
    print(template.render());
  }
}
