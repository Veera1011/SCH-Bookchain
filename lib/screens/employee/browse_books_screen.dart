import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/providers.dart';
import '../../widgets/book/book_card.dart';
import '../../widgets/common/loading_shimmers.dart';
import '../../screens/employee/ai_assistant_screen.dart';
import 'dart:async';

class BrowseBooksScreen extends ConsumerStatefulWidget {
  const BrowseBooksScreen({super.key});

  @override
  ConsumerState<BrowseBooksScreen> createState() => _BrowseBooksScreenState();
}

class _BrowseBooksScreenState extends ConsumerState<BrowseBooksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(booksFilterProvider.notifier)
          .update((state) => state.copyWith(searchQuery: query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(booksFilterProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: const Icon(Icons.search),
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
                  data: (books) => Text(
                    '${books.length} books found',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  loading: () => const Text(
                    'Loading...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  error: (_, _) => const Text(
                    'Error',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
                  if (books.isEmpty) {
                    return const Center(child: Text('No books found for your search.'));
                  }
                  return MasonryGridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisCount: isDesktop ? 6 : (size.width > 600 ? 3 : 2),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      return BookCard(book: books[index]);
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
