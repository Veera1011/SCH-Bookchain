import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../models/book_model.dart';
import 'book_details_dialog.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BookDetailsDialog(book: book),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showDetails(context),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 280, // Fixed height for grid consistency
        borderRadius: 16,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.1),
            Theme.of(context).colorScheme.surface.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.5),
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              child: Icon(Icons.book, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            child: Icon(Icons.book, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                    if (!book.isAvailable)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NOT AVAILABLE',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (List<String>.from(book.genre)..add('')).first,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                book.avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
