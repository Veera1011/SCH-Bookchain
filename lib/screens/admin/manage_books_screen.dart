import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/providers.dart';
import '../../widgets/book/book_card.dart';
import '../../widgets/common/loading_shimmers.dart';

class ManageBooksScreen extends ConsumerWidget {
  const ManageBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: locationsAsync.maybeWhen(
          data: (locs) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('ALL LOCATIONS'),
                  selected: selectedLocation == null,
                  onSelected: (val) {
                    if (val) ref.read(selectedLocationProvider.notifier).state = null;
                  },
                ),
                ...locs.map((loc) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ChoiceChip(
                    label: Text(loc.name.toUpperCase()),
                    selected: selectedLocation == loc.id,
                    onSelected: (val) {
                      if (val) ref.read(selectedLocationProvider.notifier).state = loc.id;
                    },
                  ),
                )),
              ],
            ),
          ),
          orElse: () => const Text('Inventory'),
        ),
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text('No books found in this location.'));
          }

          final size = MediaQuery.of(context).size;
          final isDesktop = size.width > 900;

          return MasonryGridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: isDesktop ? 6 : (size.width > 600 ? 3 : 2),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Stack(
                children: [
                  BookCard(book: book),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.white, size: 20),
                        onPressed: () => context.push('/admin/books/add', extra: book),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const ListShimmer(),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/books/add'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('ADD BOOK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
