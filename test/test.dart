import 'package:renderable/jinja.dart';

const source = '*{{ name("Jhon") is defined }}*';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': (String name) => 'hello $name!'}));
}
