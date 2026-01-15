class Quote {
  final String id;
  final String content;
  final String author;
  final String category;
  final bool
  isFavorite; // Only used for UI convenience after joining with favorites
  final String? created_at;

  Quote({
    required this.id,
    required this.content,
    required this.author,
    required this.category,
    this.isFavorite = false,
    this.created_at,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      // If we join with favorites table, we might have a count or boolean
      isFavorite: json['is_favorite'] == true,
      created_at: json['created_at'] as String?,
    );
  }
}
