import 'enirvonment.dart';

typedef ContextCallback = void Function(Context context);

abstract class Context {
  Environment get environment;

  Object operator [](String key);

  void operator []=(String key, Object value);

  void apply(Map<String, Object> data, ContextCallback closure);

  Object get(String key);

  bool has(String name);

  void pop();

  void push(Map<String, Object> context);

  bool remove(String name);

  void set(String key, Object value);
}
