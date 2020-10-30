import 'package:renderable/renderable.dart';

class UserTemplate implements Template {
  const UserTemplate();

  String render({Object name}) {
    final buffer = StringBuffer();
    buffer.write(_t0);

    if (false) {
      buffer.write(name);
    } else {
      buffer.write(_t1);
    }

    buffer.write(_t2);
    return buffer.toString();
  }

  static const String _t0 = '<p>hello ';

  static const String _t1 = 'world';

  static const String _t2 = '!</p>';
}
