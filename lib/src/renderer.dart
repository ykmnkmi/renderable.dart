import 'package:meta/meta.dart';

import 'enirvonment.dart';
import 'exceptions.dart';
import 'markup.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'runtime.dart';
import 'utils.dart';

class RenderContext extends Context {
  RenderContext.from(Environment environment, List<Map<String, Object?>> contexts, this.sink) : super.from(environment, contexts);

  RenderContext(Environment environment, this.sink, [Map<String, Object?>? data]) : super(environment, data);

  final StringSink sink;

  RenderContext derived({Environment? environment, List<Map<String, Object?>>? contexts, StringSink? sink}) {
    return RenderContext.from(environment ?? this.environment, contexts ?? this.contexts, sink ?? this.sink);
  }

  void write(Object? object) {
    sink.write(object);
  }

  void writeFinalized(Object? object) {
    sink.write(environment.finalize(this, object));
  }
}

class Renderer extends ExpressionResolver<RenderContext> {
  const Renderer(this.environment);

  final Environment environment;

  String render(List<Node> nodes, [Map<String, Object?>? data]) {
    final buffer = StringBuffer();
    visitAll(nodes, RenderContext(environment, buffer, data));
    return '$buffer';
  }

  @override
  void visitAll(List<Node> nodes, [RenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign assign, [RenderContext? context]) {
    final target = assign.target.accept(this, context);
    final values = assign.expression.accept(this, context);
    assignTargetsToContext(context!, target, values);
  }

  @override
  void visitAssignBlock(AssignBlock assign, [RenderContext? context]) {
    context!;

    final target = assign.target.accept(this, context);
    final buffer = StringBuffer();
    visitAll(assign.body, context.derived(sink: buffer));
    dynamic value = '$buffer';

    if (assign.filters == null || assign.filters!.isEmpty) {
      assignTargetsToContext(context, target, context.environment.autoEscape ? Markup('$value') : value);
      return;
    }

    final filters = assign.filters!;

    for (final filter in filters) {
      value = callFilter(filter, value, context);
    }

    assignTargetsToContext(context, target, context.environment.autoEscape ? Markup('$value') : value);
  }

  @override
  void visitFor(For forNode, [RenderContext? context]) {
    context!;

    final target = forNode.target.accept(this, context);

    if (forNode.hasLoop && (target == 'loop' || (target is List<String> && target.contains('loop')) || (target is NSRef && target.name == 'loop'))) {
      throw StateError('can\'t assign to special loop variable in for-loop target');
    }

    final iterable = forNode.iterable.accept(this, context);
    final orElse = forNode.orElse;

    if (iterable == null) {
      throw TypeError();
    }

    void loop(dynamic iterable) {
      var values = list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, context);
        }

        return;
      }

      Map<String, dynamic> Function(List<dynamic>, int) unpack;

      if (forNode.hasLoop) {
        unpack = (List<dynamic> values, int index) {
          final data = getDataForTargets(target, values[index]);
          dynamic previous, next;

          if (index > 0) {
            previous = values[index - 1];
          } else {
            previous = context.environment.undefined();
          }

          if (index < values.length - 1) {
            next = values[index + 1];
          } else {
            next = context.environment.undefined();
          }

          bool changed(dynamic item) {
            if (index == 0) {
              return true;
            }

            if (item == previous) {
              return false;
            }

            return true;
          }

          data['loop'] = LoopContext(index, values.length, previous, next, changed, loop);
          return data;
        };
      } else {
        unpack = (List<dynamic> values, int index) => getDataForTargets(target, values[index]);
      }

      if (forNode.test != null) {
        final test = forNode.test!;
        final filtered = <dynamic>[];

        for (var i = 0; i < values.length; i += 1) {
          final data = unpack(values, i);
          context.push(data);

          if (test.accept(this, context) as bool) {
            filtered.add(values[i]);
          }

          context.pop();
        }

        values = filtered;
      }

      for (var i = 0; i < values.length; i += 1) {
        final data = unpack(values, i);
        context.push(data);
        visitAll(forNode.body, context);
        context.pop();
      }
    }

    loop(iterable);
  }

  @override
  void visitIf(If ifNode, [RenderContext? context]) {
    context!;

    if (boolean(ifNode.test.accept(this, context))) {
      visitAll(ifNode.body, context);
      return;
    }

    var next = ifNode.nextIf;

    while (next != null) {
      if (boolean(next.test.accept(this, context))) {
        visitAll(next.body, context);
        return;
      }

      next = next.nextIf;
    }

    if (ifNode.orElse != null) {
      visitAll(ifNode.orElse!, context);
    }
  }

  @override
  void visitOutput(Output output, [RenderContext? context]) {
    context!;

    for (final node in output.nodes) {
      if (node is Data) {
        context.write(node.accept(this, context));
      } else {
        var value = node.accept(this, context);

        if (context.environment.autoEscape && value is! Markup) {
          value = Markup.escape('$value');
        }

        context.writeFinalized(value);
      }
    }
  }

  @override
  void visitWith(With wiz, [RenderContext? context]) {
    context!;

    final targets = wiz.targets.map((target) => target.accept(this, context)).toList();
    final values = wiz.values.map((value) => value.accept(this, context)).toList();

    context.push(getDataForTargets(targets, values));
    visitAll(wiz.body, context);
    context.pop();
  }

  @protected
  static void assignTargetsToContext(RenderContext context, Object? target, Object? current) {
    if (target is String) {
      context[target] = current;
      return;
    }

    if (target is List<String>) {
      List<Object?> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable<Object?>) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < target.length) {
        throw StateError('not enough values to unpack (expected ${target.length}, got ${list.length})');
      }

      if (list.length > target.length) {
        throw StateError('too many values to unpack (expected ${target.length})');
      }

      for (var i = 0; i < target.length; i++) {
        context[target[i]] = list[i];
      }

      return;
    }

    if (target is NSRef) {
      final namespace = context[target.name];

      if (namespace is! Namespace) {
        throw TemplateRuntimeError('non-namespace object');
      }

      namespace[target.attribute] = current;
      return;
    }

    throw ArgumentError.value(target, 'target');
  }

  @protected
  static Map<String, dynamic> getDataForTargets(dynamic target, dynamic current) {
    if (target is String) {
      return <String, dynamic>{target: current};
    }

    if (target is List) {
      final names = target.cast<String>();
      List<dynamic> list;

      if (current is List) {
        list = current;
      } else if (current is Iterable) {
        list = current.toList();
      } else if (current is String) {
        list = current.split('');
      } else {
        throw TypeError();
      }

      if (list.length < names.length) {
        throw StateError('not enough values to unpack (expected ${names.length}, got ${list.length})');
      }

      if (list.length > names.length) {
        throw StateError('too many values to unpack (expected ${names.length})');
      }

      final data = <String, dynamic>{};

      for (var i = 0; i < names.length; i++) {
        data[names[i]] = list[i];
      }

      return data;
    }

    throw ArgumentError.value(target, 'target');
  }
}
