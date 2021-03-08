import 'package:meta/meta.dart';

import 'enirvonment.dart';
import 'exceptions.dart';
import 'markup.dart';
import 'nodes.dart';
import 'utils.dart';

@optionalTypeArgs
typedef ContextCallback<C extends Context> = void Function(C context);

class Context {
  Context(this.environment, [Map<String, Object?>? data])
      : contexts = <Map<String, Object?>>[environment.globals],
        minimal = 2 {
    if (data != null) {
      data = Map<String, Object?>.of(data);

      if (!data.containsKey('autoescape')) {
        data['autoescape'] = environment.autoEscape;
      }

      contexts.add(data);
    } else {
      contexts.add(<String, Object?>{'autoescape': environment.autoEscape});
    }
  }

  Context.from(Context context)
      : contexts = context.contexts,
        environment = context.environment,
        minimal = context.contexts.length;

  final Environment environment;

  final List<Map<String, Object?>> contexts;

  int minimal;

  Object? operator [](String key) {
    return resolve(key);
  }

  @protected
  void pop() {
    if (contexts.length > minimal) {
      contexts.removeLast();
    }
  }

  @protected
  void push(Map<String, Object?> context) {
    contexts.add(context);
  }

  void apply<C extends Context>(Map<String, Object?> data, ContextCallback<C> closure) {
    push(data);
    closure(this as C);
    pop();
  }

  Object? escape(Object? value) {
    return get('autoescape') == true ? Markup(value) : value;
  }

  Object? get(String key) {
    for (final context in contexts.reversed) {
      if (context.containsKey(key)) {
        return context[key];
      }
    }

    return missing;
  }

  bool has(String name) {
    return contexts.any((context) => context.containsKey(name));
  }

  Object? resolve(String key) {
    final result = get(key);

    if (result == missing) {
      return environment.undefined(name: key);
    }

    return result;
  }
}

class LoopContext /* implement Iterable? */ {
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

/// The default undefined type.
///
/// This undefined type can be printed and iterated over, but every other access will raise an [UndefinedErro].
class Undefined {
  Undefined({this.hint, this.object, this.name});

  final String? hint;

  final Object? object;

  final String? name;

  @override
  int get hashCode {
    return null.hashCode;
  }

  /// Build a message about the undefined value based on how it was accessed.
  @protected
  String get undefinedMessage {
    if (hint != null) {
      return hint!;
    }

    if (object == null) {
      return '$name is undefined';
    }

    return '${object!.runtimeType} has no attribute $name';
  }

  @override
  bool operator ==(Object? other) {
    return other is Undefined;
  }

  Object? noSuchMethodError(Invocation invocation) {
    throw UndefinedError(undefinedMessage);
  }

  @override
  String toString() {
    return '';
  }
}

class Namespace {
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

  static void prepare(Node node) {
    if (node is Call) {
      if (node.expression is Name && (node.expression as Name).name == 'namespace') {
        final arguments = node.arguments == null ? <Expression>[] : node.arguments!.toList();
        node.arguments = null;

        if (node.keywordArguments != null && node.keywordArguments!.isNotEmpty) {
          final dict = DictLiteral(node.keywordArguments!.map<Pair>((keyword) => Pair(Constant<String>(keyword.key), keyword.value)).toList());
          node.keywordArguments = null;
          arguments.add(dict);
        }

        if (node.dArguments != null) {
          arguments.add(node.dArguments!);
          node.dArguments = null;
        }

        if (node.dKeywordArguments != null) {
          arguments.add(node.dKeywordArguments!);
          node.dKeywordArguments = null;
        }

        if (arguments.isNotEmpty) {
          node.arguments = <Expression>[ListLiteral(arguments)];
        }

        return;
      }
    }

    node.visitChildNodes(prepare);
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
