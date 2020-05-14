import 'package:renderable/renderable.dart';

part 'example.g.dart';

void main() {
  User user = User('jhon');
  // print(userRenderer.render(user)); // сгенерированный шаблон
  print(user.render()); // сгенерированное расширени, сокращение для варианта выше
}

@Renderable(template: 'hello {{ name }}!')
class User {
  final String name;

  const User(this.name);
}
