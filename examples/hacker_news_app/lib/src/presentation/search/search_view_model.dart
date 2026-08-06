import 'package:flutter/foundation.dart';
import '../../domain/story_repository.dart';
import '../../data/models.dart';

class SearchViewModel extends ChangeNotifier {
  final StoryRepository _repository;

  List<Story> results = [];
  bool isLoading = false;
  bool hasError = false;

  SearchViewModel(this._repository);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      results.clear();
      notifyListeners();
      return;
    }

    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      results = await _repository.searchStories(query);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      hasError = true;
      isLoading = false;
      notifyListeners();
    }
  }
}
