import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder templateGenerator(BuilderOptions options) => LibraryBuilder(TemplateGenerator(), generatedExtension: '.g.dart');
