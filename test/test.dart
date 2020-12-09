import 'package:renderable/jinja.dart';

const source = '*{{ name("jhon") }}*';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': (String name) => 'hello $name!'}));
}
