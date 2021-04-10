import 'dart:collection';

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
      data = HashMap<String, Object?>.of(data);

      if (!data.containsKey('autoescape')) {
        data['autoescape'] = environment.autoEscape;
      }

      contexts.add(data);
    } else {
      data = <String, Object?>{'autoescape': environment.autoEscape};
      contexts.add(data);
    }

    data
      ..['context'] = this
      ..['ctx'] = this
      ..['environment'] = this
      ..['env'] = this;
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

  void apply<C extends Context>(Map<String, Object?> data, ContextCallback<C> closure) {
    push(data);
    closure(this as C);
    pop();
  }

  Object? call(Object? object, [List<Object?>? positional, Map<Symbol, Object?>? named]) {
    positional ??= <Object?>[];

    if (object is! Function) {
      object = environment.getAttribute(object, 'call');
    }

    if (object is Function) {
      return Function.apply(object, positional, named);
    }
  }

  Object? escape(Object? value) {
    return value != null && value is! Markup && boolean(get('autoescape')) ? Markup(value as String) : value;
  }

  Object? escaped(Object? value) {
    return value != null && value is! Markup && boolean(get('autoescape')) ? Markup.escaped(value) : value;
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

  void pop() {
    if (contexts.length > minimal) {
      contexts.removeLast();
    }
  }

  void push(Map<String, Object?> context) {
    contexts.add(context);
  }

  Object? resolve(String key) {
    final result = get(key);

    if (result == missing) {
      return environment.undefined(name: key);
    }

    return result;
  }
}

class LoopContext extends Iterable<Object?> {
  LoopContext(this.values, this.undefined, {this.depth0 = 0, this.recurse})
      : length = values.length,
        index0 = -1;

  final List<Object?> values;

  @override
  final int length;

  final UndefinedFactory undefined;

  final String Function(Object? data, [int depth])? recurse;

  int index0;

  int depth0;

  @override
  LoopIterator get iterator {
    return LoopIterator(this);
  }

  int get index {
    return index0 + 1;
  }

  int get depth {
    return depth0 + 1;
  }

  int get revindex0 {
    return length - index;
  }

  int get revindex {
    return length - index0;
  }

  @override
  bool get first {
    return index0 == 0;
  }

  @override
  bool get last {
    return index == length;
  }

  Object? get nextitem {
    if (!last) {
      return values[index0 + 1];
    }

    return undefined(hint: 'there is no next item');
  }

  Object? get previtem {
    if (first) {
      return undefined(hint: 'there is no previous item');
    }

    return values[index0 - 1];
  }

  String call(Object? data) {
    if (recurse == null) {
      throw TypeError(/* the loop must have the 'recursive' marker to be called recursively. */);
    }

    return recurse!(data, depth);
  }

  Object cycle([Object? arg01 = missing, Object? arg02 = missing, Object? arg03 = missing]) {
    final values = <Object>[];

    if (arg01 != missing) {
      values.add(arg01!);

      if (arg02 != missing) {
        values.add(arg02!);

        if (arg03 != missing) {
          values.add(arg03!);
        }
      }
    }

    if (values.isEmpty) {
      throw TypeError(/* no items for cycling given */);
    }

    return values[index0 % values.length];
  }

  bool changed(Object? item) {
    if (index0 == 0) {
      return true;
    }

    if (item == previtem) {
      return false;
    }

    return true;
  }

  Object? operator [](String key) {
    switch (key) {
      case 'length':
        return length;
      case 'index0':
        return index0;
      case 'depth0':
        return depth0;
      case 'index':
        return index;
      case 'depth':
        return depth;
      case 'revindex0':
        return revindex0;
      case 'revindex':
        return revindex;
      case 'first':
        return first;
      case 'last':
        return last;
      case 'previtem':
        return previtem;
      case 'nextitem':
        return nextitem;
      case 'call':
        return call;
      case 'cycle':
        return cycle;
      case 'changed':
        return changed;
      default:
        throw NoSuchMethodError.withInvocation(this, Invocation.getter(Symbol(key)));
    }
  }
}

class LoopIterator extends Iterator<Object?> {
  LoopIterator(this.context);

  final LoopContext context;

  @override
  Object? get current {
    return context.values[context.index0];
  }

  @override
  bool moveNext() {
    if (context.index < context.length) {
      context.index0 += 1;
      return true;
    }

    return false;
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

  Never fail() {
    throw UndefinedError(undefinedMessage);
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    fail();
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

  final Map<String, Object?> context;

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
          final dict = DictLiteral(node.keywordArguments!
              .map<Pair>((keyword) => Pair(Constant<String>(keyword.key), keyword.value))
              .toList());
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
