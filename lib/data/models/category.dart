import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;

  const Category({required this.id, required this.name, required this.icon});

  // Helper for static categories
  static List<Category> get presets => [
    const Category(
      id: 'motivation',
      name: 'Motivation',
      icon: Icons.local_fire_department,
    ),
    const Category(id: 'love', name: 'Love', icon: Icons.favorite),
    const Category(id: 'success', name: 'Success', icon: Icons.emoji_events),
    const Category(id: 'wisdom', name: 'Wisdom', icon: Icons.lightbulb),
    const Category(
      id: 'humor',
      name: 'Humor',
      icon: Icons.sentiment_very_satisfied,
    ),
  ];
}
