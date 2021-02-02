import 'enirvonment.dart';

typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context.from(this.environment, this.contexts);

  Context(this.environment, [Map<String, Object?>? data]) : contexts = <Map<String, Object?>>[environment.globals] {
    if (data != null) {
      contexts.add(data);
    }

    minimal = contexts.length;
  }

  final Environment environment;

  final List<Map<String, Object?>> contexts;

  late int minimal;

  Object? operator [](String key) {
    return get(key);
  }

  void operator []=(String key, Object? value) {
    set(key, value);
  }

  void apply<C extends Context>(Map<String, Object?> data, ContextCallback<C> closure) {
    push(data);
    closure(this as C);
    pop();
  }

  Object? get(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return environment.undefined(name: key);
  }

  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
  }

  void pop() {
    if (contexts.length > minimal) {
      contexts.removeLast();
    }
  }

  void push(Map<String, Object?> context) {
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

  void set(String key, Object? value) {
    contexts.last[key] = value is Undefined ? null : value;
  }
}

// TODO: update
class LoopContext {
  LoopContext(this.index0, this.length, this.previtem, this.nextitem, this.changed, this.recurse) {
    index = index0 + 1;
    first = index0 == 0;
    last = index == length;
    revindex = length - index0;
    revindex0 = revindex - 1;
  }

  final int index0;

  final int length;

  final Object? previtem;

  final Object? nextitem;

  final bool Function(Object?) changed;

  final void Function(Object? data) recurse;

  late int index;

  late bool first;

  late bool last;

  late int revindex;

  late int revindex0;

  dynamic operator [](String key) {
    switch (key) {
      case 'index0':
        return index0;
      case 'length':
        return length;
      case 'previtem':
        return previtem;
      case 'nextitem':
        return nextitem;
      case 'changed':
        return changed;
      case 'index':
        return index;
      case 'first':
        return first;
      case 'last':
        return last;
      case 'revindex':
        return revindex;
      case 'revindex0':
        return revindex0;
      case 'cycle':
        return cycle;
      default:
        throw NoSuchMethodError.withInvocation(this, Invocation.getter(Symbol(key)));
    }
  }

  void call(Object? data) {
    recurse(data);
  }

  Object cycle([Object? arg01, Object? arg02, Object? arg03, Object? arg04, Object? arg05, Object? arg06, Object? arg07, Object? arg08, Object? arg09]) {
    final values = <Object>[];

    if (arg01 != null) {
      values.add(arg01);

      if (arg02 != null) {
        values.add(arg02);

        if (arg03 != null) {
          values.add(arg03);

          if (arg04 != null) {
            values.add(arg04);

            if (arg05 != null) {
              values.add(arg05);

              if (arg06 != null) {
                values.add(arg06);

                if (arg07 != null) {
                  values.add(arg07);

                  if (arg08 != null) {
                    values.add(arg08);

                    if (arg09 != null) {
                      values.add(arg09);

                      // wanna more?
                      // look at this https://api.flutter.dev/flutter/dart-ui/hashValues.html
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    if (values.isEmpty) {
      throw TypeError(/* no items for cycling given */);
    }

    return values[index0 % values.length];
  }
}

class Undefined {
  static int nextId = 1;

  Undefined({this.hint, this.object, this.name}) : id = nextId++;

  final int id;

  final String? hint;

  final Object? object;

  final String? name;

  @override
  int get hashCode {
    return 0xEE ^ id;
  }

  @override
  bool operator ==(Object? other) {
    return other is Undefined;
  }

  @override
  String toString() {
    return '';
  }
}

class Namespace {
  static Namespace factory([List<Object?>? datas]) {
    if (datas == null) {
      return Namespace();
    }

    final context = <String, Object?>{};

    for (final data in datas) {
      if (data is Map) {
        context.addAll(data.cast<String, Object?>());
      } else {
        throw TypeError();
      }
    }

    return Namespace(context);
  }

  Namespace([Map<String, Object?>? context]) : context = <String, Object?>{} {
    if (context != null) {
      this.context.addAll(context);
    }
  }

  final Map<String, dynamic> context;

  Iterable<MapEntry<String, Object?>> get entries {
    return context.entries;
  }

  Object? operator [](String key) {
    return context[key];
  }

  void operator []=(String key, Object? value) {
    context[key] = value;
  }

  @override
  String toString() {
    return 'Namespace($context)';
  }
}

class NSRef {
  NSRef(this.name, this.attribute);

  String name;

  String attribute;

  @override
  String toString() {
    return 'NSRef($name, $attribute)';
  }
}
