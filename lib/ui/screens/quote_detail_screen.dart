import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/data/services/share_service.dart';
import 'package:quote_vault/ui/widgets/add_to_collection_sheet.dart';
import 'package:go_router/go_router.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  final String? quoteId;
  final Quote? quote;

  const QuoteDetailScreen({super.key, this.quoteId, this.quote});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  late Future<Quote?> _quoteFuture;
  Quote? _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = widget.quote;
    if (_currentQuote == null && widget.quoteId != null) {
      _quoteFuture = _fetchQuote(widget.quoteId!);
    } else {
      _quoteFuture = Future.value(_currentQuote);
    }
  }

  Future<Quote?> _fetchQuote(String id) async {
    // We can add a getQuoteById method to repo or reuse getDailyQuote logic if we refactor.
    // For now, let's assume we might need to fetch it.
    // Ideally, we passed the object. If deep linking, we need fetch logic.
    // Let's implement a simple fetch in repo if needed, but for now we'll handle the passed object primarily.
    // If only ID is passed (deep link), we'll hack a fetch or show loading.
    // Actually, let's just use a simple query here for deep link support.
    try {
      // final repo = ref.read(quoteRepositoryProvider);
      // We don't have getQuoteById yet.
      // Let's fallback to "Not Found" if relying solely on ID for now,
      // or implement getQuoteById in next step if highly needed.
      // For MVP, if deep link happens, we might need to implement it.
      return null;
    } catch (e) {
      return null;
    }
  }

  void _toggleFavorite() async {
    if (_currentQuote == null) return;

    final oldQuote = _currentQuote!;
    final newQuote = Quote(
      id: oldQuote.id,
      content: oldQuote.content,
      author: oldQuote.author,
      category: oldQuote.category,
      isFavorite: !oldQuote.isFavorite,
      created_at: oldQuote.created_at,
    );

    setState(() {
      _currentQuote = newQuote;
    });

    try {
      await ref.read(quoteRepositoryProvider).toggleFavorite(newQuote.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentQuote = oldQuote;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: FutureBuilder<Quote?>(
        future: _quoteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quote = _currentQuote ?? snapshot.data;

          if (quote == null) {
            return const Center(child: Text('Quote not found'));
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    quote.content,
                    style: GoogleFonts.merriweather(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: () {
                      context.push(
                        Uri(
                          path: '/explore',
                          queryParameters: {'author': quote.author},
                        ).toString(),
                      );
                    },
                    child: Text(
                      "- ${quote.author}",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.secondary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: quote.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Favorite',
                        color: quote.isFavorite ? Colors.red : null,
                        onPressed: _toggleFavorite,
                      ),
                      _ActionButton(
                        icon: Icons.bookmark_border,
                        label: 'Save',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (context) =>
                                AddToCollectionSheet(quoteId: quote.id),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onPressed: () {
                          ShareService.shareText(
                            '"${quote.content}" - ${quote.author}\n\nShared via QuoteVault',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
