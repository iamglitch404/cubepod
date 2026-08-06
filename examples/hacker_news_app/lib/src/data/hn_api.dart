import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class HackerNewsApi {
  static const _baseUrl = 'https://hacker-news.firebaseio.com/v0';
  static const _algoliaUrl = 'https://hn.algolia.com/api/v1';

  final http.Client client;

  HackerNewsApi(this.client);

  Future<List<int>> getTopStoryIds() async {
    final response = await client.get(Uri.parse('$_baseUrl/topstories.json'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<int>();
    }
    throw Exception('Failed to load top stories');
  }

  Future<Story> getStory(int id) async {
    final response = await client.get(Uri.parse('$_baseUrl/item/$id.json'));
    if (response.statusCode == 200) {
      return Story.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load story $id');
  }

  Future<Comment> getComment(int id) async {
    final response = await client.get(Uri.parse('$_baseUrl/item/$id.json'));
    if (response.statusCode == 200) {
      return Comment.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load comment $id');
  }

  Future<List<Story>> searchStories(String query) async {
    final response = await client
        .get(Uri.parse('$_algoliaUrl/search?query=$query&tags=story'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hits = data['hits'] as List<dynamic>;
      return hits
          .map((hit) => Story(
                id: int.tryParse(hit['objectID']) ?? 0,
                title: hit['title'] ?? 'No Title',
                url: hit['url'],
                author: hit['author'] ?? 'Unknown',
                score: hit['points'] ?? 0,
                time: hit['created_at_i'] ?? 0,
                descendants: hit['num_comments'] ?? 0,
                kids: [],
              ))
          .toList();
    }
    throw Exception('Search failed');
  }
}
