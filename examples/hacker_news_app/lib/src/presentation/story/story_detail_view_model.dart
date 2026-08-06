import 'package:flutter/foundation.dart';
import '../../domain/story_repository.dart';
import '../../data/models.dart';

class StoryDetailViewModel extends ChangeNotifier {
  final StoryRepository _repository;
  final Story story;

  List<Comment> comments = [];
  bool isLoading = false;
  bool hasError = false;

  StoryDetailViewModel(this._repository, this.story) {
    _loadComments();
  }

  Future<void> _loadComments() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final results = await Future.wait(
          story.kids.take(20).map((id) => _repository.getComment(id)));

      comments = results.where((c) => !c.deleted).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      hasError = true;
      isLoading = false;
      notifyListeners();
    }
  }
}
