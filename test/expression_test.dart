import 'package:renderable/jinja.dart';

const source = 'hello {{ [0][1] }}!';

Future<void> main() async {
  final template = Template(source);
  print(template.render({'name': 'world'}));
}
