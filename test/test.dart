import 'package:renderable/jinja.dart';

const source = '*{{ 1 < 2 < 0 == 0 }}*';

void main() {
  final template = Template(source);
  // print(template.render({'list': List<int>.generate(100, (index) => index, growable: false)}));
  print(template.render({'name': 'a'}));
}
