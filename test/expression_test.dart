import 'package:renderable/jinja.dart';

void main(List<String> args) {
  final template = Template('hello {{ "name" }}!');
  print(template.render({'name': 'world'}));
}
