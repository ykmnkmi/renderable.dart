import 'package:meta/meta.dart';

import 'enirvonment.dart';
import 'exceptions.dart';
import 'nodes.dart';
import 'resolver.dart';
import 'runtime.dart';
import 'utils.dart';

abstract class RenderContext extends Context {
  RenderContext.from(Context context) : super.from(context);

  RenderContext(Environment environment, [Map<String, Object?>? data]) : super(environment, data);

  void operator []=(String key, Object? value) {
    set(key, value);
  }

  RenderContext derived();

  Object? finalize(Object? object);

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

class StringBufferRenderContext extends RenderContext {
  StringBufferRenderContext(Environment environment, {Map<String, Object?>? data, StringBuffer? buffer})
      : buffer = buffer ?? StringBuffer(),
        super(environment, data);

  StringBufferRenderContext.from(Context context, {StringBuffer? buffer})
      : buffer = buffer ?? StringBuffer(),
        super.from(context);

  final StringBuffer buffer;

  @override
  StringBufferRenderContext derived() {
    return StringBufferRenderContext(environment, buffer: buffer);
  }

  @override
  Object? finalize(Object? object) {
    return environment.finalize(this, object);
  }

  void write(Object? object) {
    buffer.write(object);
  }
}

class Renderer extends ExpressionResolver<StringBufferRenderContext> {
  @literal
  const Renderer();

  @override
  void visitAll(List<Node> nodes, [StringBufferRenderContext? context]) {
    for (final node in nodes) {
      node.accept(this, context);
    }
  }

  @override
  void visitAssign(Assign assign, [StringBufferRenderContext? context]) {
    final target = assign.target.accept(this, context);
    final values = assign.expression.accept(this, context);
    assignTargetsToContext(context!, target, values);
  }

  @override
  void visitAssignBlock(AssignBlock node, [StringBufferRenderContext? context]) {
    context!;

    final target = node.target.accept(this, context);
    final blockContext = StringBufferRenderContext.from(context);
    visitAll(node.body, blockContext);
    Object? value = blockContext.buffer.toString();

    if (node.filters == null || node.filters!.isEmpty) {
      assignTargetsToContext(context, target, context.escaped(value));
      return;
    }

    for (final filter in node.filters!) {
      value = callFilter(filter, value, context);
    }

    assignTargetsToContext(context, target, context.escaped(value));
  }

  @override
  void visitBlock(Block node, [StringBufferRenderContext? context]) {
    visitAll(node.body, context);
  }

  @override
  void visitFor(For node, [StringBufferRenderContext? context]) {
    context!;

    final targets = node.target.accept(this, context);
    final iterable = node.iterable.accept(this, context);
    final orElse = node.orElse;

    if (iterable == null) {
      throw TypeError();
    }

    String recurse(Object? iterable, [int depth = 0]) {
      var values = list(iterable);

      if (values.isEmpty) {
        if (orElse != null) {
          visitAll(orElse, context);
        }

        return '';
      }

      if (node.test != null) {
        final test = node.test!;
        final filtered = <Object?>[];

        for (final value in values) {
          final data = getDataForTargets(targets, value);
          context.push(data);

          if (test.accept(this, context) as bool) {
            filtered.add(value);
          }

          context.pop();
        }

        values = filtered;
      }

      final loop =
          LoopContext(values, context.environment.undefined, depth0: depth, recurse: node.recursive ? recurse : null);
      Map<String, Object?> Function(Object?, Object?) unpack;

      if (node.hasLoop) {
        unpack = (Object? target, Object? value) {
          final data = getDataForTargets(target, value);
          data['loop'] = loop;
          return data;
        };
      } else {
        unpack = getDataForTargets;
      }

      for (final value in loop) {
        final data = unpack(targets, value);
        context.push(data);
        visitAll(node.body, context);
        context.pop();
      }

      return '';
    }

    recurse(iterable);
  }

  @override
  void visitIf(If node, [StringBufferRenderContext? context]) {
    context!;

    if (boolean(node.test.accept(this, context))) {
      visitAll(node.body, context);
      return;
    }

    var next = node.nextIf;

    while (next != null) {
      if (boolean(next.test.accept(this, context))) {
        visitAll(next.body, context);
        return;
      }

      next = next.nextIf;
    }

    if (node.orElse != null) {
      visitAll(node.orElse!, context);
    }
  }

  @override
  void visitInclude(Include node, [StringBufferRenderContext? context]) {
    context!;

    try {
      final name = node.template.accept(this, context);
      Template template;

      if (name is List) {
        template = context.environment.selectTemplate(name);
      } else {
        template = context.environment.getTemplate(name);
      }

      if (node.withContext) {
        template.accept(this, context);
      } else {
        template.accept(this, context.derived());
      }
    } on TemplateNotFound {
      if (!node.ignoreMissing) {
        rethrow;
      }
    }
  }

  @override
  void visitOutput(Output node, [StringBufferRenderContext? context]) {
    context!;

    for (final item in node.nodes) {
      if (item is Data) {
        context.write(item.accept(this, context));
      } else {
        var value = item.accept(this, context);
        value = context.escape(value);
        value = context.finalize(value);
        context.write(value);
      }
    }
  }

  @override
  void visitScope(Scope node, [StringBufferRenderContext? context]) {
    node.modifier.accept(this, context);
  }

  @override
  void visitScopedContextModifier(ScopedContextModifier node, [StringBufferRenderContext? context]) {
    context!;

    final data = {for (final key in node.options.keys) key: node.options[key]!.accept(this)};
    context.apply<StringBufferRenderContext>(data, (context) {
      visitAll(node.body, context);
    });
  }

  @override
  void visitTemplate(Template node, [StringBufferRenderContext? context]) {
    visitAll(node.nodes, context);
  }

  @override
  void visitWith(With node, [StringBufferRenderContext? context]) {
    context!;

    final targets = node.targets.map((target) => target.accept(this, context)).toList();
    final values = node.values.map((value) => value.accept(this, context)).toList();

    context.push(getDataForTargets(targets, values));
    visitAll(node.body, context);
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
  static Map<String, Object?> getDataForTargets(Object? target, Object? current) {
    if (target is String) {
      return <String, Object?>{target: current};
    }

    if (target is List) {
      final names = target.cast<String>();
      List<Object?> list;

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

      final data = <String, Object?>{};

      for (var i = 0; i < names.length; i++) {
        data[names[i]] = list[i];
      }

      return data;
    }

    throw ArgumentError.value(target, 'target');
  }
}
