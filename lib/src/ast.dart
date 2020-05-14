library ast;

import 'visitor.dart';

part 'ast/name.dart';
part 'ast/text.dart';

abstract class Expression extends Node {}

abstract class Node {
  R accept<C, R>(Visitor<C, R> visitor, C context);
}

abstract class Statement extends Node {}
