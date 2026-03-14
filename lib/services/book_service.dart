import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class BookService {
  final SupabaseClient _supabase;

  BookService(this._supabase);

  Future<List<BookModel>> getBooks({
    String? locationId,
    String? genre,
    bool availableOnly = false,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    // ✅ Build ALL filters first on PostgrestFilterBuilder
    var query = _supabase.from('books').select().eq('is_active', true);

    if (locationId != null) {
      query = query.eq('location_id', locationId);
    }

    if (genre != null && genre != 'All') {
      query = query.contains('genre', [genre]);
    }

    if (availableOnly) {
      query = query.gt('available_copies', 0);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'title.ilike.%$searchQuery%,author.ilike.%$searchQuery%',
      );
    }

    // ✅ Apply order + range LAST and await directly — no reassignment
    if (limit != null && offset != null) {
      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List).map((json) => BookModel.fromJson(json)).toList();
    }

    if (limit != null) {
      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((json) => BookModel.fromJson(json)).toList();
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => BookModel.fromJson(json)).toList();
  }

  // ── Get Book By ID ────────────────────────────────────────────────────────
  Future<BookModel> getBookById(String id) async {
    final data = await _supabase.from('books').select().eq('id', id).single();
    return BookModel.fromJson(data);
  }

  // ── Get Book By QR ────────────────────────────────────────────────────────
  Future<BookModel?> getBookByQr(String qrCode) async {
    try {
      final data = await _supabase
          .from('books')
          .select()
          .eq('qr_code', qrCode)
          .single();
      return BookModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ── Create Book ───────────────────────────────────────────────────────────
  Future<BookModel> createBook({
    required String title,
    required String author,
    required String locationId,
    String? isbn,
    String? description,
    List<String> genre = const [],
    int totalCopies = 1,
    String? coverUrl,
  }) async {
    final result = await _supabase
        .from('books')
        .insert({
          'title': title,
          'author': author,
          'location_id': locationId,
          'isbn': isbn,
          'description': description,
          'genre': genre,
          'total_copies': totalCopies,
          'available_copies': totalCopies,
          'cover_url': coverUrl,
        })
        .select()
        .single();

    return BookModel.fromJson(result);
  }

  // ── Update Book ───────────────────────────────────────────────────────────
  Future<void> updateBook(String id, Map<String, dynamic> updates) async {
    await _supabase.from('books').update(updates).eq('id', id);
  }

  // ── Deactivate Book ───────────────────────────────────────────────────────
  Future<void> deactivateBook(String id) async {
    await _supabase.from('books').update({'is_active': false}).eq('id', id);
  }

  // ── Watch Books Realtime ──────────────────────────────────────────────────
  Stream<List<BookModel>> watchBooks(String locationId) {
    return _supabase
        .from('books')
        .stream(primaryKey: ['id'])
        .eq('location_id', locationId) // ✅ only ONE .eq() on stream
        .map(
          (list) => list
              .where(
                (e) => e['is_active'] == true,
              ) // ✅ filter is_active in Dart
              .map((e) => BookModel.fromJson(e))
              .toList(),
        );
  }

  Stream<List<BookModel>> watchAllBooks() {
    return _supabase
        .from('books')
        .stream(primaryKey: ['id'])
        .map(
          (list) => list
              .where((e) => e['is_active'] == true)
              .map((e) => BookModel.fromJson(e))
              .toList(),
        );
  }

  // ── Upload Book Cover ─────────────────────────────────────────────────────
  Future<String> uploadBookCover(Uint8List bytes, String fileName) async {
    final extension = fileName.split('.').last;
    final path = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    await _supabase.storage.from('book-covers').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );

    return _supabase.storage.from('book-covers').getPublicUrl(path);
  }
}
