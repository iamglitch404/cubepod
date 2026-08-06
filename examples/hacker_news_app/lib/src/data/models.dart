class Story {
  final int id;
  final String title;
  final String? url;
  final String author;
  final int score;
  final int time;
  final int descendants;
  final List<int> kids;

  Story({
    required this.id,
    required this.title,
    this.url,
    required this.author,
    required this.score,
    required this.time,
    required this.descendants,
    required this.kids,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      url: json['url'],
      author: json['by'] ?? 'Unknown',
      score: json['score'] ?? 0,
      time: json['time'] ?? 0,
      descendants: json['descendants'] ?? 0,
      kids: List<int>.from(json['kids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'by': author,
        'score': score,
        'time': time,
        'descendants': descendants,
        'kids': kids,
      };
}

class Comment {
  final int id;
  final String author;
  final String text;
  final int time;
  final List<int> kids;
  final bool deleted;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.time,
    required this.kids,
    required this.deleted,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      author: json['by'] ?? 'Unknown',
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
      kids: List<int>.from(json['kids'] ?? []),
      deleted: json['deleted'] ?? false,
    );
  }
}
