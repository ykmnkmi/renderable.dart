import 'enirvonment.dart';

typedef ContextCallback = void Function(Context context);

class Context {
  Context(this.environment, [Map<String, dynamic>? context]) : contexts = <Map<String, dynamic>>[environment.globals] {
    if (context != null) {
      contexts.add(context);
    }
  }

  final Environment environment;

  final List<Map<String, dynamic>> contexts;

  dynamic operator [](String key) {
    return get(key);
  }

  void operator []=(String key, Object value) {
    set(key, value);
  }

  void apply(Map<String, dynamic> data, ContextCallback closure) {
    push(data);
    closure(this);
    pop();
  }

  dynamic get(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return null;
  }

  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
  }

  void pop() {
    if (contexts.length > 2) {
      contexts.removeLast();
    }
  }

  void push(Map<String, dynamic> context) {
    contexts.add(context);
  }

  bool remove(String name) {
    for (final context in contexts.reversed) {
      if (context.containsKey(name)) {
        context.remove(name);
        return true;
      }
    }

    return false;
  }

  void set(String key, Object value) {
    contexts.last[key] = value;
  }
}
