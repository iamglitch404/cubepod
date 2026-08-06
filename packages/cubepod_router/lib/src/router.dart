import 'package:flutter/widgets.dart';

class CubeRoute {
  final String path;
  final WidgetBuilder builder;

  CubeRoute({required this.path, required this.builder});
}

/// A declarative, reactive router for Flutter applications.
class CubeRouter {
  final List<CubeRoute> routes;

  CubeRouter(this.routes);

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final route = routes.where((r) => r.path == settings.name).firstOrNull;
    if (route != null) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, _, anim) => route.builder(context),
      );
    }
    return null;
  }
}
