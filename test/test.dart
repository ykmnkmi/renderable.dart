import 'package:renderable/jinja.dart';

const source = '*{{ 2**3 }}*';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': (String name) => 'hello $name!'}));
}
