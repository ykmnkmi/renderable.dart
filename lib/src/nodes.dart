import 'exceptions.dart';
import 'utils.dart';
import 'visitor.dart';

part 'nodes/expressions.dart';
part 'nodes/helpers.dart';
part 'nodes/statements.dart';

abstract class Node {
  const Node();

  R accept<C, R>(Visitor<C, R> visitor, [C? context]);
}

class Data extends Node {
  Data([this.data = '']);

  String data;

  @override
  R accept<C, R>(Visitor<C, R> visitor, [C? context]) {
    return visitor.visitData(this, context);
  }

  @override
  String toString() {
    return 'Data(\'${data.replaceAll('\'', '\\\'').replaceAll('\r\n', r'\n').replaceAll('\n', r'\n')}\')';
  }
}

abstract class Expression extends Node {}

abstract class Statement extends Node {}

abstract class Helper extends Node {}
