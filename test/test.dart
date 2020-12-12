import 'package:renderable/jinja.dart';

const source = '*{{ {1: 2} }}*';

void main() {
  // final template = Template(source);
  final template = Template('{{ "o" is in "foo" }}|{{ "foo" is in "foo" }}|'
      '{{ "b" is in "foo" }}|{{ 1 is in ((1, 2)) }}|'
      '{{ 3 is in ((1, 2)) }}|{{ 1 is in [1, 2] }}|'
      '{{ 3 is in [1, 2] }}|{{ "foo" is in {"foo": 1}}}|'
      '{{ "baz" is in {"bar": 1}}}');
  print(template.nodes);
  print(template.render());
}
