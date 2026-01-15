import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/ui/widgets/quote_card.dart';
import 'package:quote_vault/ui/widgets/daily_quote_card.dart';
import 'package:quote_vault/ui/widgets/add_to_collection_sheet.dart';
import 'package:quote_vault/data/services/share_service.dart';

// -- Providers for Home Screen Logic -- with basic caching/pagination support needs manual handling or a proper library like infinite_scroll_pagination
// For this MVP, we'll implement a simple StateNotifier for pagination.

class HomeState {
  final List<Quote> quotes;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  HomeState({
    required this.quotes,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
  });

  HomeState copyWith({
    List<Quote>? quotes,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return HomeState(
      quotes: quotes ?? this.quotes,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  late final QuoteRepository _repository;

  @override
  HomeState build() {
    _repository = ref.watch(quoteRepositoryProvider);
    return HomeState(quotes: []);
  }

  Future<void> fetchQuotes({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = HomeState(quotes: [], isLoading: true);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true);
    }

    try {
      final newQuotes = await _repository.getQuotes(page: state.page);

      state = state.copyWith(
        quotes: refresh ? newQuotes : [...state.quotes, ...newQuotes],
        isLoading: false,
        hasMore: newQuotes.length >= 20,
        page: state.page + 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite(String quoteId) async {
    final index = state.quotes.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      final oldQuote = state.quotes[index];
      final newQuote = Quote(
        id: oldQuote.id,
        content: oldQuote.content,
        author: oldQuote.author,
        category: oldQuote.category,
        isFavorite: !oldQuote.isFavorite,
        created_at: oldQuote.created_at,
      );

      final updatedQuotes = List<Quote>.from(state.quotes);
      updatedQuotes[index] = newQuote;
      state = state.copyWith(quotes: updatedQuotes);

      try {
        await _repository.toggleFavorite(quoteId);
      } catch (e) {
        // Revert on error
        updatedQuotes[index] = oldQuote;
        state = state.copyWith(
          quotes: updatedQuotes,
          error: 'Failed to update favorite',
        );
      }
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class PaginationLoadingIndicator extends StatelessWidget {
  const PaginationLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

final dailyQuoteProvider = FutureProvider.autoDispose<Quote>((ref) async {
  return ref.watch(quoteRepositoryProvider).getDailyQuote();
});

// -- UI --

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initial fetch
    Future.microtask(
      () => ref.read(homeProvider.notifier).fetchQuotes(refresh: true),
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeProvider.notifier).fetchQuotes();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    // We can use a separate FutureProvider for daily quote to not interfere with main list
    final dailyQuoteAsync = ref.watch(dailyQuoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoteVault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(dailyQuoteProvider);
          await ref.read(homeProvider.notifier).fetchQuotes(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: dailyQuoteAsync.when(
                data: (quote) => DailyQuoteCard(
                  quote: quote,
                  onTap: () {
                    // Navigate to detail or show options
                  },
                ),
                error: (e, _) => const SizedBox.shrink(),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            if (homeState.error != null && homeState.quotes.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text('Error: ${homeState.error}')),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childCount: homeState.quotes.length,
                itemBuilder: (context, index) {
                  final quote = homeState.quotes[index];
                  return QuoteCard(
                    quote: quote,
                    onFavorite: () {
                      ref.read(homeProvider.notifier).toggleFavorite(quote.id);
                    },
                    onShare: () {
                      ShareService.shareText(
                        '"${quote.content}" - ${quote.author}\n\nShared via QuoteVault',
                      );
                    },
                    onAddToCollection: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) =>
                            AddToCollectionSheet(quoteId: quote.id),
                      );
                    },
                  );
                },
              ),
            ),
            if (homeState.isLoading && homeState.quotes.isNotEmpty)
              const SliverToBoxAdapter(child: PaginationLoadingIndicator()),

            if (!homeState.isLoading &&
                homeState.quotes.isEmpty &&
                homeState.error == null)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_quote, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No quotes found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your vault is empty.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Quick jump to categories
        },
        child: const Icon(Icons.category),
      ),
    );
  }
}
