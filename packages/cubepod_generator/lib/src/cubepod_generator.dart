import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:cubepod_annotation/cubepod_annotation.dart';
import 'package:source_gen/source_gen.dart';

class CubePodGenerator extends GeneratorForAnnotation<CubePodInit> {
  static const _injectable = TypeChecker.fromUrl(
    'package:cubepod_annotation/cubepod_annotation.dart#CubeInjectable',
  );

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final lib = element.library;
    if (lib == null) return '';

    // Collect classes from this library and everything it imports.
    final classes = <ClassElement>{};
    classes.addAll(lib.classes);
    for (final imported in lib.firstFragment.importedLibraries) {
      classes.addAll(imported.classes);
    }

    // Build a map of injectable classes and their dep info.
    final registry = <String, _ServiceInfo>{};
    for (final cls in classes) {
      final name = cls.name;
      if (name == null) continue;

      final ann = _injectable.firstAnnotationOf(cls);
      if (ann == null) continue;

      final reader = ConstantReader(ann);
      final scopeIndex =
          reader.read('scope').objectValue.getField('index')?.toIntValue() ?? 0;
      final scope = CubeScope.values[scopeIndex].name;
      final alias =
          reader.read('name').isNull ? null : reader.read('name').stringValue;

      final ctor = cls.unnamedConstructor ??
          cls.constructors.where((c) => !c.isFactory).firstOrNull;

      if (ctor == null) {
        throw InvalidGenerationSourceError(
          'No usable constructor found for $name. Add an unnamed constructor.',
          element: cls,
        );
      }

      final deps =
          ctor.formalParameters.map((p) => p.type.getDisplayString()).toList();

      registry[name] = _ServiceInfo(name, scope, deps, alias);
    }

    // Make sure every dependency is also registered.
    for (final service in registry.values) {
      for (final dep in service.deps) {
        if (!registry.containsKey(dep)) {
          throw InvalidGenerationSourceError(
            'Missing registration: ${service.type} depends on $dep, '
            'but $dep is not annotated with @CubeInjectable.',
          );
        }
      }
    }

    // Catch circular deps before generating anything.
    final done = <String>{};
    final inProgress = <String>{};

    void checkForCycles(String node, List<String> path) {
      if (inProgress.contains(node)) {
        final cycle = [...path, node].join(' → ');
        throw InvalidGenerationSourceError(
          'Circular dependency: $cycle',
        );
      }
      if (done.contains(node)) return;

      inProgress.add(node);
      for (final dep in registry[node]!.deps) {
        checkForCycles(dep, [...path, node]);
      }
      inProgress.remove(node);
      done.add(node);
    }

    for (final node in registry.keys) {
      checkForCycles(node, []);
    }

    // Topological sort so dependencies are registered before dependants.
    final ordered = <_ServiceInfo>[];
    final seen = <String>{};

    void addToOrder(String node) {
      if (seen.contains(node)) return;
      for (final dep in registry[node]!.deps) {
        addToOrder(dep);
      }
      seen.add(node);
      ordered.add(registry[node]!);
    }

    for (final node in registry.keys) {
      addToOrder(node);
    }

    // Emit the generated setup function.
    final out = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT')
      ..writeln()
      ..writeln('void \$initCubePod() {');

    for (final service in ordered) {
      final nameArg = service.alias != null ? ", name: '${service.alias}'" : '';
      final args = service.deps.map((d) {
        final target = registry[d]!;
        final depNameArg =
            target.alias != null ? ", name: '${target.alias}'" : "";
        return 'c.get<$d>($depNameArg)';
      }).join(', ');

      out.writeln(
        '  CubePod.register<${service.type}>('
        '(c) => ${service.type}($args), '
        'scope: Scope.${service.scope}$nameArg);',
      );
    }

    out.writeln('}');
    return out.toString();
  }
}

class _ServiceInfo {
  final String type;
  final String scope;
  final List<String> deps;
  final String? alias;

  _ServiceInfo(this.type, this.scope, this.deps, this.alias);
}
