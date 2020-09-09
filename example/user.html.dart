import 'package:renderable/renderable.dart';

class UserTemplate implements Template {
  const UserTemplate();

  String render({
    Object name,
  }) {
    final buffer = StringBuffer();
    buffer.write(_s0);
    buffer.write(name);
    buffer.write(_s1);
    return buffer.toString();
  }

  static const String _s0 = '<p>hello ';

  static const String _s1 = '!</p>';
}
