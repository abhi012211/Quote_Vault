import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/ui/widgets/quote_card.dart';

final collectionItemsProvider = FutureProvider.autoDispose
    .family<List<Quote>, String>((ref, collectionId) async {
      return ref
          .watch(quoteRepositoryProvider)
          .getQuotesInCollection(collectionId);
    });

class CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;
  final String collectionName;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(collectionItemsProvider(collectionId));

    return Scaffold(
      appBar: AppBar(title: Text(collectionName)),
      body: itemsAsync.when(
        data: (quotes) {
          if (quotes.isEmpty)
            return const Center(
              child: Text('No quotes in this collection yet.'),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return Dismissible(
                key: Key(quote.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref
                      .read(quoteRepositoryProvider)
                      .removeFromCollection(collectionId, quote.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Quote removed from collection')),
                  );
                  // Refresh the list to reflect changes if not using a stream
                  ref.invalidate(collectionItemsProvider(collectionId));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: QuoteCard(
                    quote: quote,
                    onTap: () {
                      context.push('/quote/${quote.id}', extra: quote);
                    },
                  ),
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
