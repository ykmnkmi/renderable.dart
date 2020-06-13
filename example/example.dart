import 'package:renderable/renderable.dart';

part 'example.g.dart';

void main() {
  final user = User('jhon');
  // print(userRenderer.render(user)); // сгенерированный шаблон
  print(user.render()); // сгенерированное расширени, сокращение для варианта выше
}

@Renderable(path: 'user.html')
class User {
  final String name;

  const User(this.name);
}
