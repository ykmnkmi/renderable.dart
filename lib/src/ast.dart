library ast;

import 'util.dart';
import 'visitor.dart';

part 'ast/statement/if.dart';
part 'ast/text.dart';
part 'ast/variable.dart';

abstract class Expression extends Node {}

abstract class Node {
  R accept<C, R>(Visitor<C, R> visitor, [C context]);
}

abstract class Statement extends Node {}
