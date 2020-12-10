import 'package:renderable/jinja.dart';

const source = '*{{ name is defined }}*';

void main() {
  final template = Template(source);
  print(template.render({'name': null}));
}
