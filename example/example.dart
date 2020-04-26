import 'dart:io';

import 'package:renderable/renderable.dart';

import 'example.g.dart';

void main(List<String> arguments) {
  User user = User('jhon');
  stdout.writeln(user.render());
}

@Template.generate('user.html')
class User {
  final String name;

  const User(this.name);
}
