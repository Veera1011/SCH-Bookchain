class BookModel {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final List<String> genre;
  final String language;
  final String locationId;
  final int totalCopies;
  final int availableCopies;
  final String? coverUrl;
  final String? ebookUrl;
  final double avgRating;
  final int ratingCount;
  final String condition;
  final String? qrCode;
  final bool isActive;
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    required this.genre,
    required this.language,
    required this.locationId,
    required this.totalCopies,
    required this.availableCopies,
    this.coverUrl,
    this.ebookUrl,
    required this.avgRating,
    required this.ratingCount,
    required this.condition,
    this.qrCode,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAvailable => availableCopies > 0;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      description: json['description'],
      genre: List<String>.from(json['genre'] ?? []),
      language: json['language'] ?? 'en',
      locationId: json['location_id'],
      totalCopies: json['total_copies'] ?? 1,
      availableCopies: json['available_copies'] ?? 1,
      coverUrl: json['cover_url'],
      ebookUrl: json['ebook_url'],
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      condition: json['condition'] ?? 'good',
      qrCode: json['qr_code'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'description': description,
      'genre': genre,
      'language': language,
      'location_id': locationId,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'cover_url': coverUrl,
      'ebook_url': ebookUrl,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'condition': condition,
      'qr_code': qrCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
