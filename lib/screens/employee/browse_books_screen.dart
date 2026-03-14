import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final List<String> _genres = [
    'All',
    'Leadership',
    'Technology',
    'Finance',
    'Self-Help',
    'Management',
    'Marketing',
    'Design',
    'Psychology',
    'History',
  ];

  @override
  void initState() {
    super.initState();
  }

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
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final genre = _genres[index];
                final isSelected =
                    filter.genre == genre ||
                    (filter.genre == null && genre == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref
                          .read(booksFilterProvider.notifier)
                          .update(
                            (state) => state.copyWith(
                              genre: genre == 'All' ? null : genre,
                            ),
                          );
                    },
                  ),
                );
              },
            ),
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
              onRefresh: () async {
                return ref.refresh(booksProvider);
              },
              child: booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No books found.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookCard(
                        book: book,
                      );
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
