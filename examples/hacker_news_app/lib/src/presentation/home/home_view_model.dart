import 'package:flutter/foundation.dart';
import '../../domain/story_repository.dart';
import '../../data/models.dart';

class HomeViewModel extends ChangeNotifier {
  final StoryRepository _repository;

  List<int> _topStoryIds = [];
  final List<Story> stories = [];
  bool isLoading = false;
  bool hasError = false;

  HomeViewModel(this._repository) {
    _loadTopStories();
  }

  Future<void> _loadTopStories({bool forceRefresh = false}) async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      _topStoryIds =
          await _repository.getTopStoryIds(forceRefresh: forceRefresh);
      if (forceRefresh) {
        stories.clear();
      }
      await loadMore();
    } catch (e) {
      hasError = true;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading && stories.isNotEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      final startIndex = stories.length;
      final endIndex = (startIndex + 20).clamp(0, _topStoryIds.length);
      final idsToFetch = _topStoryIds.sublist(startIndex, endIndex);

      final newStories =
          await Future.wait(idsToFetch.map((id) => _repository.getStory(id)));

      stories.addAll(newStories);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      hasError = true;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return _loadTopStories(forceRefresh: true);
  }
}
