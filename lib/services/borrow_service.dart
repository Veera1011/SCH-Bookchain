import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/borrow_record_model.dart';

class BorrowService {
  final SupabaseClient _supabase;

  BorrowService(this._supabase);

  // ── Borrow Book ───────────────────────────────────────────────────────────
  Future<void> borrowBook({
    required String bookId,
    required String bookTitle,
    required String locationId,
    required String reason,
    DateTime? isbnVerifiedAt,
  }) async {
    if (reason.trim().length < 20) {
      throw Exception('Reason must be at least 20 characters.');
    }

    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profileData = await _supabase
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single();

    final dueDate = DateTime.now().add(const Duration(days: 14));

    await _supabase.from('borrow_records').insert({
      'book_id': bookId,
      'book_title': bookTitle,
      'user_id': user.id,
      'user_name': profileData['name'],
      'location_id': locationId,
      'reason': reason.trim(),
      'due_date': dueDate.toIso8601String(),
      'status': 'borrowed',
      if (isbnVerifiedAt != null)
        'isbn_borrowed_verified_at': isbnVerifiedAt.toIso8601String(),
    });
  }

  // ── Return Book ───────────────────────────────────────────────────────────
  Future<void> returnBook({
    required String recordId,
    required String summary,
    required int rating,
    String? review,
    DateTime? isbnReturnedVerifiedAt,
  }) async {
    if (summary.trim().length < 100) {
      throw Exception('Summary must be at least 100 characters.');
    }
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }

    await _supabase
        .from('borrow_records')
        .update({
          'status': 'returned',
          'returned_at': DateTime.now().toIso8601String(),
          'summary': summary.trim(),
          'rating': rating,
          'review': review?.trim(),
          if (isbnReturnedVerifiedAt != null)
            'isbn_returned_verified_at': isbnReturnedVerifiedAt.toIso8601String(),
        })
        .eq('id', recordId);
  }

  // ── My Active Borrows ─────────────────────────────────────────────────────
  Future<List<BorrowRecordModel>> getMyActiveBorrows() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // ✅ All filters before .order() — no reassignment after transform
    final data = await _supabase
        .from('borrow_records')
        .select()
        .eq('user_id', user.id)
        .inFilter('status', ['borrowed', 'overdue'])
        .order('due_date', ascending: true);

    return (data as List)
        .map((json) => BorrowRecordModel.fromJson(json))
        .toList();
  }

  // ── My History ────────────────────────────────────────────────────────────
  Future<List<BorrowRecordModel>> getMyHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // ✅ Filters → order → range, all chained, never reassigned
    final data = await _supabase
        .from('borrow_records')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'returned')
        .order('returned_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((json) => BorrowRecordModel.fromJson(json))
        .toList();
  }

  // ── All Records (Admin) ───────────────────────────────────────────────────
  Future<List<BorrowRecordModel>> getAllRecords({
    String? locationId,
    String? status,
    String? userId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    // ✅ Build filters on PostgrestFilterBuilder
    var query = _supabase.from('borrow_records').select();

    if (locationId != null) query = query.eq('location_id', locationId);
    if (status != null) query = query.eq('status', status);
    if (userId != null) query = query.eq('user_id', userId);
    if (from != null) query = query.gte('borrowed_at', from.toIso8601String());
    if (to != null) query = query.lte('borrowed_at', to.toIso8601String());

    // ✅ Apply order + range at the very end — never reassign back to query
    final data = await query
        .order('borrowed_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((json) => BorrowRecordModel.fromJson(json))
        .toList();
  }


  // ── Join Waitlist ─────────────────────────────────────────────────────────
  Future<void> joinWaitlist(String bookId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('waitlist').insert({
      'book_id': bookId,
      'user_id': user.id,
    });
  }

  // ── Leave Waitlist ────────────────────────────────────────────────────────
  Future<void> leaveWaitlist(String bookId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('waitlist')
        .delete()
        .eq('book_id', bookId)
        .eq('user_id', user.id);
  }
}
