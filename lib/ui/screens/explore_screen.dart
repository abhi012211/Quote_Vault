import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/models/quote.dart';
import 'package:quote_vault/data/repositories/quote_repository.dart';
import 'package:quote_vault/ui/widgets/quote_card.dart';
import 'package:quote_vault/data/services/share_service.dart';
import 'package:quote_vault/ui/widgets/add_to_collection_sheet.dart';

class ExploreState {
  final List<Quote> quotes;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;
  final String? searchQuery;
  final String? selectedCategory;
  final String? selectedAuthor;

  ExploreState({
    required this.quotes,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
    this.searchQuery,
    this.selectedCategory,
    this.selectedAuthor,
  });

  ExploreState copyWith({
    List<Quote>? quotes,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
    String? searchQuery,
    String? selectedCategory,
    String? selectedAuthor,
    bool clearQuotes = false,
  }) {
    return ExploreState(
      quotes: clearQuotes ? [] : (quotes ?? this.quotes),
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedAuthor: selectedAuthor ?? this.selectedAuthor,
    );
  }
}

class ExploreNotifier extends Notifier<ExploreState> {
  late final QuoteRepository _repository;

  @override
  ExploreState build() {
    _repository = ref.watch(quoteRepositoryProvider);
    return ExploreState(quotes: []);
  }

  Future<void> fetchQuotes({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        clearQuotes: true,
        page: 0,
        hasMore: true,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true);
    }

    try {
      final newQuotes = await _repository.getQuotes(
        page: state.page,
        searchQuery: state.searchQuery,
        category: state.selectedCategory,
        author: state.selectedAuthor,
      );

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

  void updateSearch(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(
      searchQuery: query,
      selectedCategory: null,
      selectedAuthor: null,
    );
    fetchQuotes(refresh: true);
  }

  void selectCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(
      selectedCategory: category,
      searchQuery: null,
      selectedAuthor: null,
    );
    fetchQuotes(refresh: true);
  }

  void selectAuthor(String author) {
    if (state.selectedAuthor == author) return;
    state = state.copyWith(
      selectedAuthor: author,
      searchQuery: null,
      selectedCategory: null,
    );
    fetchQuotes(refresh: true);
  }

  void clearFilters() {
    state = ExploreState(quotes: []);
  }
}

final exploreProvider = NotifierProvider<ExploreNotifier, ExploreState>(
  ExploreNotifier.new,
);

class ExploreScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialAuthor;
  final String? initialQuery;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialAuthor,
    this.initialQuery,
  });

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'Motivation',
    'Love',
    'Success',
    'Wisdom',
    'Humor',
    'Life',
    'Philosophy',
    'Art',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize state from parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(exploreProvider.notifier);
      if (widget.initialCategory != null) {
        notifier.selectCategory(widget.initialCategory!);
      } else if (widget.initialAuthor != null) {
        notifier.selectAuthor(widget.initialAuthor!);
      } else if (widget.initialQuery != null) {
        _searchController.text = widget.initialQuery!;
        notifier.updateSearch(widget.initialQuery!);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(exploreProvider.notifier).fetchQuotes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    final notifier = ref.read(exploreProvider.notifier);

    final isFiltering =
        exploreState.searchQuery != null ||
        exploreState.selectedCategory != null ||
        exploreState.selectedAuthor != null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search quotes, authors...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      notifier.clearFilters();
                    },
                  )
                : null,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) notifier.updateSearch(value);
          },
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Display
          if (exploreState.selectedCategory != null ||
              exploreState.selectedAuthor != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  if (exploreState.selectedCategory != null)
                    Chip(
                      label: Text('Category: ${exploreState.selectedCategory}'),
                      onDeleted: () => notifier.clearFilters(),
                    ),
                  if (exploreState.selectedAuthor != null)
                    Chip(
                      label: Text('Author: ${exploreState.selectedAuthor}'),
                      onDeleted: () => notifier.clearFilters(),
                    ),
                ],
              ),
            ),

          // Categories Grid (Only if not filtering/searching)
          if (!isFiltering)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return InkWell(
                    onTap: () => notifier.selectCategory(category),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            // Results List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => notifier.fetchQuotes(refresh: true),
                child: exploreState.quotes.isEmpty && !exploreState.isLoading
                    ? ListView(
                        children: [
                          const SizedBox(height: 50),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  exploreState.error != null
                                      ? 'Error loading quotes'
                                      : 'No quotes found',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (exploreState.error != null)
                                  Text(
                                    exploreState.error!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : MasonryGridView.count(
                        controller: _scrollController,
                        crossAxisCount: 2,
                        padding: const EdgeInsets.all(8),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        itemCount:
                            exploreState.quotes.length +
                            (exploreState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == exploreState.quotes.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final quote = exploreState.quotes[index];
                          return QuoteCard(
                            quote: quote,
                            onFavorite: () {
                              ref
                                  .read(quoteRepositoryProvider)
                                  .toggleFavorite(quote.id);
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
                            onAuthorTap: () {
                              notifier.selectAuthor(quote.author);
                            },
                            onTap: () {
                              context.push('/quote/${quote.id}', extra: quote);
                            },
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
