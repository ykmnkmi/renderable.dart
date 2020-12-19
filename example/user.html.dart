import 'package:renderable/core.dart';
import 'package:renderable/filters.dart' as filters;

class UserTemplate implements Renderable {
  const UserTemplate();

  String render({dynamic name}) {
    final buffer = StringBuffer();
    buffer.write('hello ');
    buffer.write(filters.lower(name));
    buffer.write('!');
    return buffer.toString();
  }
}
