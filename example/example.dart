import 'package:renderable/renderable.dart';

import 'example.r.g.dart';

void main() {
  User user = User('jhon');
  print(user.render());
}

@Renderable(template: 'hello {{ name }}!')
class User {
  final String name;

  const User(this.name);
}
