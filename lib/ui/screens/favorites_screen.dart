import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/ui/widgets/quote_card.dart';

// Simple FutureProvider for favorites
final favoritesProvider = FutureProvider.autoDispose<List<Quote>>((ref) async {
  final repo = ref.watch(quoteRepositoryProvider);
  return repo.getFavorites();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favoritesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return const Center(child: Text('No favorites yet!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: QuoteCard(
                  quote: quote,
                  onFavorite: () async {
                    await ref
                        .read(quoteRepositoryProvider)
                        .toggleFavorite(quote.id);
                    ref.invalidate(favoritesProvider); // Refresh list
                  },
                  onTap: () {
                    context.push('/quote/${quote.id}', extra: quote);
                  },
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
