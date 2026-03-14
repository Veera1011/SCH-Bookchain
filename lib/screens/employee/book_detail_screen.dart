import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      book.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey[300]),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${book.author}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${book.avgRating.toStringAsFixed(1)} (${book.ratingCount} reviews)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: book.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            book.isAvailable ? 'Available (${book.availableCopies} left)' : 'Waitlist',
                            style: TextStyle(
                              color: book.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description ?? 'No description available.',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Genres',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: book.genre.map((g) => Chip(label: Text(g))).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text('ISBN: ${book.isbn ?? 'N/A'}'),
                    Text('Language: ${book.language}'),
                    Text('Condition: ${book.condition}'),
                    const SizedBox(height: 80), // Padding for bottom button
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      bottomSheet: bookAsync.whenData((book) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: book.isAvailable
                  ? () => context.push('/borrow/${book.id}')
                  : () async {
                      try {
                        await ref.read(borrowServiceProvider).joinWaitlist(book.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Joined waitlist!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error joining waitlist: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: book.isAvailable ? null : Colors.orange,
              ),
              child: Text(book.isAvailable ? 'Borrow This Book' : 'Join Waitlist'),
            ),
          ),
        );
      }).valueOrNull,
    );
  }
}
