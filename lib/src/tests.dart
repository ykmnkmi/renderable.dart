import 'package:renderable/anotations.dart';

@Test()
bool defined(Object value) {
  if (value == null) {
    return false;
  }

  return true;
}
