import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/cubepod_generator.dart';

/// Defines the entry point for the `build_runner` to run the CubePod generator.
Builder cubepodBuilder(BuilderOptions options) =>
    SharedPartBuilder([CubePodGenerator()], 'cubepod');
