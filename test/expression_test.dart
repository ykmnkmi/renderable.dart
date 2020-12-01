import 'package:renderable/jinja.dart';

void main() {
  final template = Template('hello {{ "name" }}!');
  print(template.render({'name': 'world'}));
}
