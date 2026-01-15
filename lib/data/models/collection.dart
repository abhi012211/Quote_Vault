class Collection {
  final String id;
  final String name;
  final String userId;

  Collection({required this.id, required this.name, required this.userId});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String,
    );
  }
}
