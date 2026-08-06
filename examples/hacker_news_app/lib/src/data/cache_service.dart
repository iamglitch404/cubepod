import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class CacheService {
  final SharedPreferences prefs;

  CacheService(this.prefs);

  void cacheStory(Story story) {
    prefs.setString('story_${story.id}', jsonEncode(story.toJson()));
  }

  Story? getCachedStory(int id) {
    final str = prefs.getString('story_$id');
    if (str != null) {
      return Story.fromJson(jsonDecode(str));
    }
    return null;
  }

  void cacheTopStoryIds(List<int> ids) {
    prefs.setString('top_stories', jsonEncode(ids));
  }

  List<int>? getCachedTopStoryIds() {
    final str = prefs.getString('top_stories');
    if (str != null) {
      final List<dynamic> data = jsonDecode(str);
      return data.cast<int>();
    }
    return null;
  }
}
