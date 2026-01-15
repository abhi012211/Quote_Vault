import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/ui/screens/collections_screen.dart'; // Reuse collectionsProvider

class AddToCollectionSheet extends ConsumerWidget {
  final String quoteId;

  const AddToCollectionSheet({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      // maximize height roughly 50%
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add to Collection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) {
                  return const Center(
                    child: Text('No collections. Create one!'),
                  );
                }
                return ListView.builder(
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(collection.name),
                      onTap: () async {
                        try {
                          await ref
                              .read(quoteRepositoryProvider)
                              .addToCollection(collection.id, quoteId);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${collection.name}'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Collection'),
            onTap: () {
              // Close sheet and show dialog? Or show dialog on top?
              // Showing dialog on top of sheet works in Flutter usually.
              showDialog(
                context: context,
                builder: (context) => const CreateCollectionDialog(),
              ).then((_) {
                // Refresh list after dialog closes
                ref.invalidate(collectionsProvider);
              });
            },
          ),
        ],
      ),
    );
  }
}
