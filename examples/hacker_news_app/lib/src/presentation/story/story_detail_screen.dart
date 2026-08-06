import 'package:flutter/material.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:html_unescape/html_unescape.dart';
import 'story_detail_view_model.dart';

class StoryDetailScreen extends StatelessWidget {
  const StoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: CubeListenableBuilder<StoryDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError && viewModel.comments.isEmpty) {
            return const Center(child: Text('Failed to load comments'));
          }

          if (viewModel.comments.isEmpty) {
            return const Center(child: Text('No comments yet.'));
          }

          return ListView.builder(
            itemCount: viewModel.comments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    viewModel.story.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
              }

              final comment = viewModel.comments[index - 1];
              // Removing html tags roughly for MVP
              final plainText = unescape
                  .convert(comment.text.replaceAll(RegExp(r'<[^>]*>'), ''));
              return ListTile(
                title: Text(comment.author,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(plainText),
              );
            },
          );
        },
      ),
    );
  }
}
