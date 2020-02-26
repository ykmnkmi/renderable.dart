import 'package:renderable/renderable.dart';

void main(List<String> arguments) {
  final Map<String, Object> context = <String, Object>{'name': 'jhon'};
  final Template renderable = r'hello {{ name }}'.parse();

  print(renderable.render(context));
  print(r'hello {{ name }}'.render(context));
}
