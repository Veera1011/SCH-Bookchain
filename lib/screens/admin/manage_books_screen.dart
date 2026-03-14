import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common/loading_shimmers.dart';

class ManageBooksScreen extends ConsumerWidget {
  const ManageBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text('No books found in this location.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 70,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: book.coverUrl != null
                          ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                          : Icon(Icons.book, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  title: Text(
                    book.title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${book.author}\n${book.availableCopies} COPIES LEFT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => context.push('/admin/books/add', extra: book),
                  ),
                ),
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
