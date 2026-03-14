import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/book_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookDetailsDialog extends StatelessWidget {
  final BookModel book;

  const BookDetailsDialog({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 300,
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(Icons.book, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title.toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BY ${book.author.toUpperCase()}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Icons.category_outlined, 'GENRE', (List<String>.from(book.genre)..add('N/A')).first),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.inventory_2_outlined, 'AVAILABILITY', '${book.availableCopies} COPIES AVAILABLE'),
                    const SizedBox(height: 12),
                    _buildInfoRow(context, Icons.star_outline, 'RATING', '${book.avgRating.toStringAsFixed(1)} / 5.0'),
                    const SizedBox(height: 24),
                    Text(
                      book.description ?? 'No description available for this book.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5),
                    ),
                    if (book.isbn != null && book.isbn!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(context, Icons.qr_code_2, 'ISBN', book.isbn!),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: book.isAvailable
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        foregroundColor: book.isAvailable
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                      ),
                      onPressed: book.isAvailable ? () {
                        Navigator.pop(context);  // close dialog
                        context.push('/borrow/${book.id}'); // navigate to borrow screen
                      } : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(book.isAvailable ? Icons.library_add : Icons.block, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            book.isAvailable ? 'BORROW THIS BOOK' : 'NOT AVAILABLE',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
