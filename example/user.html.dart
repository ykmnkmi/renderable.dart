import 'package:renderable/renderable.dart';

class UserTemplate implements Template {
  const UserTemplate();

  String render({dynamic user}) {
    return 'hello ${lower(user.name)}!';
  }
}
