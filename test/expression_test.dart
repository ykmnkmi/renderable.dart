import 'package:renderable/jinja.dart';

void main() {
  final template = Template('hello {{ [name, 1] }}!');
  print(template.render({'name': 'world'}));
}
