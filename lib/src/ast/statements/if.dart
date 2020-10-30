part of '../../ast.dart';

class IfStatement extends Statement {
  IfStatement(this.pairs, [this.orElse]) : assert(pairs.isNotEmpty);

  final Map<Test, Node> pairs;

  final Node orElse;

  @override
  void accept(Visitor visitor) {
    return visitor.visitIf(this);
  }

  @override
  String toString() {
    final buffer = StringBuffer('If ');
    final pairs = this.pairs.entries.toList(growable: false);

    buffer.write(pairs.first.key);
    buffer.write(' ');
    buffer.write(pairs.first.value);

    for (final pair in pairs.skip(1)) {
      buffer.write(' Else If ');
      buffer.write(pair.key);
      buffer.write('  ');
      buffer.write(pair.value);
    }

    if (orElse != null) {
      buffer.write(' Else ');
      buffer.write(orElse);
    }

    return buffer.toString();
  }
}
