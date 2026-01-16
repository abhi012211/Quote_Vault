import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quote.dart';
import '../models/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/widget_service.dart';

part 'quote_repository.g.dart';

class QuoteRepository {
  final SupabaseClient _supabase;

  QuoteRepository(this._supabase);

  Future<List<Quote>> getQuotes({
    int page = 0,
    int pageSize = 20,
    String? category,
    String? searchQuery,
    String? author,
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      var query = _supabase.from('quotes').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      if (author != null) {
        query = query.eq('author', author);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'content.ilike.%$searchQuery%,author.ilike.%$searchQuery%',
        );
      }

      final start = page * pageSize;
      final end = start + pageSize - 1;

      final response = await query
          .range(start, end)
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      // If user is logged in, fetch their favorites to mark isFavorite
      Set<String> favoriteIds = {};
      if (user != null && data.isNotEmpty) {
        final quoteIds = data.map((e) => e['id']).toList();
        final favoritesResponse = await _supabase
            .from('favorites')
            .select('quote_id')
            .eq('user_id', user.id)
            .inFilter('quote_id', quoteIds);

        favoriteIds = (favoritesResponse as List)
            .map((e) => e['quote_id'] as String)
            .toSet();
      }

      return data.map((e) {
        final Map<String, dynamic> quoteData = Map.from(e);
        quoteData['is_favorite'] = favoriteIds.contains(e['id']);
        return Quote.fromJson(quoteData);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching quotes: $e');
    }
  }

  Future<void> toggleFavorite(String quoteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Check if already favorite
      final existing = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('quote_id', quoteId)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from('favorites').delete().eq('id', existing['id']);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'quote_id': quoteId,
        });
      }
    } catch (e) {
      throw Exception('Error toggling favorite: $e');
    }
  }

  Future<List<Quote>> getFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Fetch favorites with quote details
      // Note: This relies on Supabase foreign key join
      final response = await _supabase
          .from('favorites')
          .select('quotes(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) {
        final quoteData = e['quotes'] as Map<String, dynamic>;
        // Since it's in favorites table, it IS favorite
        final Map<String, dynamic> finalData = Map.from(quoteData);
        finalData['is_favorite'] = true;
        return Quote.fromJson(finalData);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching favorites: $e');
    }
  }

  // Collections
  Future<List<Collection>> getCollections() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('collections')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => Collection.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching collections: $e');
    }
  }

  Future<void> createCollection(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _supabase.from('collections').insert({
        'user_id': user.id,
        'name': name,
      });
    } catch (e) {
      throw Exception('Error creating collection: $e');
    }
  }

  Future<void> addToCollection(String collectionId, String quoteId) async {
    try {
      await _supabase.from('collection_items').insert({
        'collection_id': collectionId,
        'quote_id': quoteId,
      });
    } catch (e) {
      // Ignore duplicate key error safely or handle it
      if (!e.toString().contains('duplicate key')) {
        rethrow;
      }
    }
  }

  Future<void> removeFromCollection(String collectionId, String quoteId) async {
    try {
      await _supabase.from('collection_items').delete().match({
        'collection_id': collectionId,
        'quote_id': quoteId,
      });
    } catch (e) {
      throw Exception('Error removing from collection: $e');
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    try {
      // Items will cascade delete if foreign keys are set up correctly,
      // otherwise verify schema. Assuming cascade delete on FK.
      await _supabase.from('collections').delete().eq('id', collectionId);
    } catch (e) {
      throw Exception('Error deleting collection: $e');
    }
  }

  Future<List<Quote>> getQuotesInCollection(String collectionId) async {
    try {
      final response = await _supabase
          .from('collection_items')
          .select('quotes(*)')
          .eq('collection_id', collectionId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      // Reuse similar logic to getFavorites but for now simple mapping
      // NOTE: We might want to also know if these are favorited by the user,
      // effectively we should reuse the "getQuotes" logic or do a manual enrichment.
      // For MVP, let's just return the quotes.
      return data.map((e) => Quote.fromJson(e['quotes'])).toList();
    } catch (e) {
      throw Exception('Error fetching collection items: $e');
    }
  }

  Future<Quote> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString('daily_quote_date');
    final lastQuoteId = prefs.getString('daily_quote_id');

    if (lastDate == today && lastQuoteId != null) {
      // Fetch stored quote
      try {
        final response = await _supabase
            .from('quotes')
            .select()
            .eq('id', lastQuoteId)
            .single();
        final Map<String, dynamic> quoteData = Map.from(response);
        // We should also check favorite status
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final fav = await _supabase
              .from('favorites')
              .select()
              .eq('user_id', user.id)
              .eq('quote_id', lastQuoteId)
              .maybeSingle();
          quoteData['is_favorite'] = fav != null;
        }
        return Quote.fromJson(quoteData);
      } catch (_) {
        // If fetch fails (maybe deleted), fetch new random
      }
    }

    // Fetch new random quote
    try {
      // Get a random quote.
      // Efficient random in Supabase for large tables is tricky, but for smaller ones we can use numeric offsets or a specialized function.
      // For now, let's fetch a small batch from recent and pick one, or use a Postgres function if we had one.
      // Simpler approach: Fetch top 50, pick random.
      final response = await _supabase.from('quotes').select().limit(50);
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) throw Exception('No quotes found');

      final randomData = (data..shuffle()).first;

      await prefs.setString('daily_quote_date', today);
      await prefs.setString('daily_quote_id', randomData['id']);

      final Map<String, dynamic> quoteData = Map.from(randomData);
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final fav = await _supabase
            .from('favorites')
            .select()
            .eq('user_id', user.id)
            .eq('quote_id', randomData['id'])
            .maybeSingle();
        quoteData['is_favorite'] = fav != null;
      }

      // Update Widget
      try {
        await WidgetService.updateWidget(
          quoteData['content'],
          quoteData['author'],
          quoteData['id'],
        );
      } catch (_) {}

      return Quote.fromJson(quoteData);
    } catch (e) {
      throw Exception('Error fetching daily quote: $e');
    }
  }
}

@Riverpod(keepAlive: true)
QuoteRepository quoteRepository(Ref ref) {
  return QuoteRepository(Supabase.instance.client);
}
