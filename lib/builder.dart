import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder renderableBuilder(BuilderOptions options) {
  return SharedPartBuilder(<Generator>[RenderableGenerator()], 'renderable');
}
