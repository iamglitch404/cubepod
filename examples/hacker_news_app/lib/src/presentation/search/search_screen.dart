import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'search_view_model.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CubeListenableBuilder<SearchViewModel>(
          builder: (context, viewModel, child) => TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search Hacker News...',
              border: InputBorder.none,
            ),
            onSubmitted: viewModel.search,
          ),
        ),
      ),
      body: CubeListenableBuilder<SearchViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return const Center(child: Text('Search failed'));
          }

          if (viewModel.results.isEmpty) {
            return const Center(child: Text('No results'));
          }

          return ListView.builder(
            itemCount: viewModel.results.length,
            itemBuilder: (context, index) {
              final story = viewModel.results[index];
              return ListTile(
                title: Text(story.title),
                subtitle: Text('${story.score} points by ${story.author}'),
                onTap: () => context.push('/story/${story.id}'),
                trailing: story.url != null
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => launchUrl(Uri.parse(story.url!)),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
