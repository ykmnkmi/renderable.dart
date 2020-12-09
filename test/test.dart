import 'package:renderable/jinja.dart';

const source = '*{{ name is defined }}*';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': null}));
}
