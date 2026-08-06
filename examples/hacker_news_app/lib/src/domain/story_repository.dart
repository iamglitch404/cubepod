import '../data/hn_api.dart';
import '../data/cache_service.dart';
import '../data/models.dart';

class StoryRepository {
  final HackerNewsApi api;
  final CacheService cache;

  StoryRepository(this.api, this.cache);

  Future<List<int>> getTopStoryIds({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = cache.getCachedTopStoryIds();
      if (cached != null) return cached;
    }

    try {
      final ids = await api.getTopStoryIds();
      cache.cacheTopStoryIds(ids);
      return ids;
    } catch (e) {
      final cached = cache.getCachedTopStoryIds();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Story> getStory(int id) async {
    final cached = cache.getCachedStory(id);
    if (cached != null) {
      // Fetch in background to update cache optionally, but return cached for now
      _fetchAndCacheStory(id);
      return cached;
    }
    return _fetchAndCacheStory(id);
  }

  Future<Story> _fetchAndCacheStory(int id) async {
    final story = await api.getStory(id);
    cache.cacheStory(story);
    return story;
  }

  Future<Comment> getComment(int id) {
    return api.getComment(id);
  }

  Future<List<Story>> searchStories(String query) {
    return api.searchStories(query);
  }
}
