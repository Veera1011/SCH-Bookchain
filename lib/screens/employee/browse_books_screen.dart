import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/providers.dart';
import '../../widgets/book/book_card.dart';
import '../../widgets/common/loading_shimmers.dart';
import '../../screens/employee/ai_assistant_screen.dart';
import '../../models/book_model.dart';
import 'dart:async';

class BrowseBooksScreen extends ConsumerStatefulWidget {
  const BrowseBooksScreen({super.key});

  @override
  ConsumerState<BrowseBooksScreen> createState() => _BrowseBooksScreenState();
}

class _BrowseBooksScreenState extends ConsumerState<BrowseBooksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isMoodMode = false;
  bool _isAiLoading = false;
  List<String>? _semanticResults;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _semanticResults = null;
        _isAiLoading = false;
      });
      if (!_isMoodMode) {
        ref.read(booksFilterProvider.notifier).update((state) => state.copyWith(searchQuery: query));
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (_isMoodMode) {
        setState(() => _isAiLoading = true);
        try {
          final allBooks = ref.read(booksProvider).value ?? [];
          final results = await ref.read(aiServiceProvider).semanticSearch(query, allBooks);
          setState(() {
            _semanticResults = results;
            _isAiLoading = false;
          });
        } catch (e) {
          setState(() => _isAiLoading = false);
        }
      } else {
        ref.read(booksFilterProvider.notifier).update((state) => state.copyWith(searchQuery: query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(booksFilterProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final booksAsync = ref.watch(booksProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _isMoodMode 
                        ? 'Describe your mood or intent...' 
                        : 'Search by title or author...',
                      prefixIcon: Icon(
                        _isMoodMode ? Icons.auto_awesome : Icons.search,
                        color: _isMoodMode ? Colors.amber : null,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'AI Mood Search',
                  child: FilterChip(
                    label: const Icon(Icons.auto_awesome, size: 20),
                    selected: _isMoodMode,
                    onSelected: (val) {
                      setState(() {
                        _isMoodMode = val;
                        _semanticResults = null;
                        _searchController.clear();
                      });
                      _onSearchChanged('');
                    },
                    selectedColor: Colors.amber.withValues(alpha: 0.2),
                    checkmarkColor: Colors.amber,
                    side: BorderSide(
                      color: _isMoodMode ? Colors.amber : colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAiLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),
            ),
          booksAsync.when(
            data: (books) {
              if (books.isEmpty && filter.searchQuery?.isEmpty == true) {
                return const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Your local library is ready.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                booksAsync.when(
                  data: (books) {
                    int count = 0;
                    if (_isMoodMode && _semanticResults != null) {
                      count = _semanticResults!.length;
                    } else {
                      count = books.length;
                    }
                    return Text(
                      _isMoodMode 
                        ? '$count AI suggestions'
                        : '$count books found',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                  loading: () => const Text(
                    'Loading...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  error: (_, _) => const Text(
                    'Error',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!_isMoodMode)
                  Row(
                    children: [
                      const Text(
                        'Available only',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: filter.availableOnly,
                        onChanged: (val) {
                          ref
                              .read(booksFilterProvider.notifier)
                              .update(
                                (state) => state.copyWith(availableOnly: val),
                              );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: () => ref.refresh(booksProvider.future),
              child: booksAsync.when(
                data: (books) {
                  List<BookModel> displayBooks = books;
                  
                  if (_isMoodMode && _semanticResults != null) {
                    displayBooks = books.where((b) => _semanticResults!.contains(b.id)).toList();
                    // Sort displayBooks to match the order returned by AI if possible
                    displayBooks.sort((BookModel a, BookModel b) {
                      return _semanticResults!.indexOf(a.id).compareTo(_semanticResults!.indexOf(b.id));
                    });
                  }

                  if (displayBooks.isEmpty) {
                    return Center(
                      child: Text(
                        _isMoodMode 
                          ? 'AI couldn\'t find matches for this mood.'
                          : 'No books found for your search.'
                      )
                    );
                  }
                  
                  return MasonryGridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisCount: isDesktop ? 6 : (size.width > 600 ? 3 : 2),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: displayBooks.length,
                    itemBuilder: (context, index) {
                      return BookCard(book: displayBooks[index]);
                    },
                  );
                },
                loading: () => const BookGridShimmer(),
                error: (e, stack) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: booksAsync.maybeWhen(
        data: (books) => FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIAssistantScreen(availableBooks: books),
                fullscreenDialog: true,
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.auto_awesome, color: Colors.amber),
          label: Text(
            'ASK AI',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
