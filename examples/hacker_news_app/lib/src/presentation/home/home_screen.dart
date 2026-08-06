import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_view_model.dart';
import '../../core/theme_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.get<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hacker News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          ListenableBuilder(
            listenable: themeService.themeMode,
            builder: (context, _) {
              final isDark = themeService.themeMode.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: themeService.toggleTheme,
              );
            },
          ),
        ],
      ),
      body: CubeListenableBuilder<HomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.stories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError && viewModel.stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load stories'),
                  ElevatedButton(
                    onPressed: viewModel.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!viewModel.isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  viewModel.loadMore();
                  return true;
                }
                return false;
              },
              child: ListView.builder(
                itemCount:
                    viewModel.stories.length + (viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == viewModel.stories.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final story = viewModel.stories[index];
                  return ListTile(
                    title: Text(story.title),
                    subtitle: Text(
                        '${story.score} points by ${story.author} | ${story.descendants} comments'),
                    onTap: () => context.push('/story/${story.id}'),
                    trailing: story.url != null
                        ? IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(Uri.parse(story.url!)),
                          )
                        : null,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
