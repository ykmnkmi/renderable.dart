import 'package:renderable/jinja.dart';

const source = '*{{ list[0:5:1] }}*';

void main() {
  final template = Template(source);
  // print(template.render({'list': List<int>.generate(100, (index) => index, growable: false)}));
  print(template.render({'list': ['a', 2, '3']}));
}
