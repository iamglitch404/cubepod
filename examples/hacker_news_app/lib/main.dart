import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

import 'src/core/theme_service.dart';
import 'src/data/hn_api.dart';
import 'src/data/cache_service.dart';
import 'src/domain/story_repository.dart';
import 'src/presentation/home/home_view_model.dart';
import 'src/presentation/home/home_screen.dart';
import 'src/presentation/story/story_detail_view_model.dart';
import 'src/presentation/story/story_detail_screen.dart';
import 'src/presentation/search/search_view_model.dart';
import 'src/presentation/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Root DI Registrations
  CubePod.register((c) => ThemeService(), scope: Scope.singleton);
  CubePod.register((c) => HackerNewsApi(http.Client()), scope: Scope.singleton);
  CubePod.register((c) => CacheService(prefs), scope: Scope.singleton);
  CubePod.register(
      (c) => StoryRepository(c.get<HackerNewsApi>(), c.get<CacheService>()),
      scope: Scope.singleton);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CubeScope.runAsAmbient(
      CubePod.root,
      Builder(builder: (context) {
        final themeService = context.get<ThemeService>();

        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return CubeScope(
                  overrides: (c) {
                    c.register((c) => HomeViewModel(c.get<StoryRepository>()),
                        scope: Scope.scoped);
                  },
                  child: const HomeScreen(),
                );
              },
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) {
                return CubeScope(
                  overrides: (c) {
                    c.register((c) => SearchViewModel(c.get<StoryRepository>()),
                        scope: Scope.scoped);
                  },
                  child: const SearchScreen(),
                );
              },
            ),
            GoRoute(
              path: '/story/:id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                // Retrieve story from cache safely since we just navigated from a list
                final story = CubePod.get<CacheService>().getCachedStory(id);
                if (story == null) {
                  return const Scaffold(
                      body: Center(child: Text('Story not found')));
                }

                return CubeScope(
                  overrides: (c) {
                    c.register(
                        (c) => StoryDetailViewModel(
                            c.get<StoryRepository>(), story),
                        scope: Scope.scoped);
                  },
                  child: const StoryDetailScreen(),
                );
              },
            ),
          ],
        );

        return ListenableBuilder(
          listenable: themeService.themeMode,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'Hacker News CubePod',
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeService.themeMode.value,
              routerConfig: router,
            );
          },
        );
      }),
    );
  }
}
