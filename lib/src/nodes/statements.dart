part of '../nodes.dart';

class Assign extends Statement {
  Assign(this.target, this.expression);

  final Expression target;

  final Expression expression;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAssign(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    visitor(expression);
  }

  @override
  String toString() {
    return 'Assign($target, $expression)';
  }
}

class AssignBlock extends Statement {
  AssignBlock(this.target, this.body, [this.filters]);

  Expression target;

  List<Node> body;

  List<Filter>? filters;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitAssignBlock(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    body.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'AssignBlock($target, $body';

    if (filters != null && filters!.isNotEmpty) {
      result = '$result, $filters';
    }

    return '$result)';
  }
}

class For extends Statement {
  For(this.target, this.iterable, this.body, {this.hasLoop = false, this.orElse, this.test, this.recursive = false});

  Expression target;

  Expression iterable;

  List<Node> body;

  bool hasLoop;

  List<Node>? orElse;

  Test? test;

  bool recursive;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitFor(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(target);
    visitor(iterable);
    body.forEach(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'For($target, $iterable';

    if (body.isNotEmpty) {
      result = '$result, $body';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    if (recursive) {
      result = '$result, recursive: $recursive';
    }

    return '$result)';
  }
}

class If extends Statement {
  If(this.test, this.body, {this.nextIf, this.orElse});

  Expression test;

  List<Node> body;

  If? nextIf;

  List<Node>? orElse;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitIf(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    visitor(test);

    for (final node in body) {
      visitor(node);
    }

    nextIf?.visitChildNodes(visitor);
    orElse?.forEach(visitor);
  }

  @override
  String toString() {
    var result = 'If($test, $body';

    if (nextIf != null) {
      result = '$result, next: $nextIf';
    }

    if (orElse != null) {
      result = '$result, orElse: $orElse';
    }

    return '$result)';
  }
}

class Output extends Statement {
  Output(this.nodes);

  List<Node> nodes;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitOutput(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    nodes.forEach(visitor);
  }

  @override
  String toString() {
    return 'Output(${nodes.join(', ')})';
  }
}

class With extends Statement {
  With(this.targets, this.values, this.body);

  List<Expression> targets;

  List<Expression> values;

  List<Node> body;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitWith(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {
    targets.forEach(visitor);
    values.forEach(visitor);
    body.forEach(visitor);
  }

  @override
  String toString() {
    return 'With($targets, $values, $body)';
  }
}

abstract class ImportContext {
  bool get withContext;

  set withContext(bool withContext);
}

class Include extends Statement implements ImportContext {
  Include(this.template, {this.ignoreMissing = false, this.withContext = true});

  Expression template;

  bool ignoreMissing;

  @override
  bool withContext;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitInclude(this, context);
  }

  @override
  void visitChildNodes(NodeVisitor visitor) {}

  @override
  String toString() {
    var result = 'Include(';

    if (ignoreMissing) {
      result = '${result}ignoreMissing, ';
    }

    if (withContext) {
      result = '${result}withContext, ';
    }

    return '$result$template)';
  }
}
