import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_flip_builder/page_flip_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/book_model.dart';
import '../../widgets/book/book_details_dialog.dart';

class BookDetailsFlipScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailsFlipScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final flipKey = GlobalKey<PageFlipBuilderState>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: bookAsync.when(
        data: (book) => SafeArea(
          child: Center(
            child: PageFlipBuilder(
              key: flipKey,
              frontBuilder: (_) => _buildFront(context, book, flipKey),
              backBuilder: (_) => _buildBack(context, book, ref, flipKey),
              flipAxis: Axis.horizontal,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildFront(BuildContext context, BookModel book, GlobalKey<PageFlipBuilderState> flipKey) {
    return GestureDetector(
      onTap: () => flipKey.currentState?.flip(),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.book, size: 100, color: Colors.white24),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BY ${book.author.toUpperCase()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.touch_app, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'TAP TO FLIP',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context, BookModel book, WidgetRef ref, GlobalKey<PageFlipBuilderState> flipKey) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOOK DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flip_to_front, size: 20),
                onPressed: () => flipKey.currentState?.flip(), 
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.description ?? 'No description available for this masterpiece.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'GENRES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: book.genre.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        g.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  BookDetailsDialog(book: book),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: book.availableCopies > 0
                  ? () => context.push('/borrow/${book.id}')
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(book.availableCopies > 0 ? 'BORROW NOW' : 'OUT OF STOCK'),
            ),
          ),
        ],
      ),
    );
  }
}
