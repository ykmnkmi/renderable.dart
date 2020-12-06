import 'package:renderable/jinja.dart';

const source = '*{{ name }}*';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': 'name'}));
}
