import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleBookInfo {
  final String title;
  final String author;
  final String? description;
  final List<String> genres;
  final String? coverUrl;
  final String? isbn;
  final String? publisher;
  final int? pageCount;

  GoogleBookInfo({
    required this.title,
    required this.author,
    this.description,
    required this.genres,
    this.coverUrl,
    this.isbn,
    this.publisher,
    this.pageCount,
  });
}

class GoogleBooksService {
  // No API key needed for basic lookup (free tier)
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<GoogleBookInfo?> lookupByIsbn(String isbn) async {
    // Clean the ISBN - remove dashes and spaces
    final cleanIsbn = isbn.replaceAll('-', '').replaceAll(' ', '');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=isbn:$cleanIsbn'),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final items = data['items'] as List?;
      if (items == null || items.isEmpty) return null;

      final volumeInfo = items[0]['volumeInfo'] as Map<String, dynamic>;

      // Extract authors
      final authorsRaw = volumeInfo['authors'] as List?;
      final author = authorsRaw != null
          ? authorsRaw.join(', ')
          : 'Unknown Author';

      // Extract categories/genres
      final categoriesRaw = volumeInfo['categories'] as List?;
      final genres = categoriesRaw != null
          ? List<String>.from(categoriesRaw)
          : <String>[];

      // Extract cover image - prefer the largest available
      String? coverUrl;
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks != null) {
        // extraLarge → large → medium → thumbnail (best to worst)
        coverUrl = imageLinks['extraLarge'] ??
            imageLinks['large'] ??
            imageLinks['medium'] ??
            imageLinks['thumbnail'];
        
        // Google Books returns http - force https
        if (coverUrl != null) {
          coverUrl = coverUrl.replaceFirst('http://', 'https://');
          // Remove zoom/edge parameters for better quality
          coverUrl = coverUrl.replaceAll('&edge=curl', '');
        }
      }

      // Extract ISBN-13 from identifiers
      final identifiers = volumeInfo['industryIdentifiers'] as List?;
      String? isbn13;
      if (identifiers != null) {
        for (final id in identifiers) {
          if (id['type'] == 'ISBN_13') {
            isbn13 = id['identifier'];
            break;
          }
        }
        // Fallback to ISBN-10
        if (isbn13 == null) {
          for (final id in identifiers) {
            if (id['type'] == 'ISBN_10') {
              isbn13 = id['identifier'];
              break;
            }
          }
        }
      }

      return GoogleBookInfo(
        title: volumeInfo['title'] ?? 'Unknown Title',
        author: author,
        description: volumeInfo['description'],
        genres: genres,
        coverUrl: coverUrl,
        isbn: isbn13 ?? cleanIsbn,
        publisher: volumeInfo['publisher'],
        pageCount: volumeInfo['pageCount'],
      );
    } catch (e) {
      print('Google Books API error: $e');
      return null;
    }
  }
}
