import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/cubepod_generator.dart';

Builder cubepodBuilder(BuilderOptions options) =>
    SharedPartBuilder([CubePodGenerator()], 'cubepod');
