import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/collection.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';

final collectionsProvider = FutureProvider.autoDispose<List<Collection>>((
  ref,
) async {
  return ref.watch(quoteRepositoryProvider).getCollections();
});

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return const Center(child: Text('Create your first collection!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return InkWell(
                onTap: () {
                  context.push(
                    '/collection/${collection.id}',
                    extra: collection.name,
                  );
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Collection'),
                      content: Text(
                        'Are you sure you want to delete "${collection.name}"? This will remove all quotes from this collection.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              await ref
                                  .read(quoteRepositoryProvider)
                                  .deleteCollection(collection.id);
                              ref.invalidate(collectionsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Collection deleted'),
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
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        collection.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateCollectionDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateCollectionDialog extends ConsumerStatefulWidget {
  const CreateCollectionDialog({super.key});

  @override
  ConsumerState<CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState
    extends ConsumerState<CreateCollectionDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Collection Name (e.g. Work)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) return;
                  setState(() => _isLoading = true);
                  try {
                    await ref
                        .read(quoteRepositoryProvider)
                        .createCollection(_controller.text.trim());
                    ref.invalidate(collectionsProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    // Handle error
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
