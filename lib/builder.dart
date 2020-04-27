import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder rendererGenerator(BuilderOptions options) =>
    LibraryBuilder(RenedererGenerator(), generatedExtension: '.r.g.dart');
