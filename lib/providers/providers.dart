import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../models/book_model.dart';
import '../models/borrow_record_model.dart';
import '../models/location_model.dart';
import '../models/notification_model.dart';

import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/borrow_service.dart';
import '../services/admin_service.dart';
import '../services/ai_service.dart';

// Services
final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

final bookServiceProvider = Provider<BookService>((ref) {
  return BookService(ref.watch(supabaseProvider));
});

final borrowServiceProvider = Provider<BorrowService>((ref) {
  return BorrowService(ref.watch(supabaseProvider));
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(supabaseProvider));
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.watch(supabaseProvider));
});

// Auth & Profile
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  // Always fetch fresh profile if auth state is valid
  final authState = ref.watch(authStateProvider).value;
  if (authState?.session == null) return null;
  return await ref.watch(authServiceProvider).getCurrentProfile();
});

// App Settings
final appSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.from('app_settings').stream(primaryKey: ['id']).map((list) {
    if (list.isNotEmpty) {
      return list.first;
    }
    // Default fallback
    return {'primary_color': '#1A3557', 'is_dark_mode': false};
  });
});

// Admin Providers
final pendingUsersProvider = StreamProvider.autoDispose<List<ProfileModel>>((
  ref,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.watchPendingUsers();
});

final activeUsersProvider = StreamProvider.autoDispose<List<ProfileModel>>((
  ref,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.watchActiveUsers();
});

final allUsersProvider = StreamProvider.autoDispose<List<ProfileModel>>((
  ref,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.watchAllUsers();
});

final pendingUsersCountProvider = StreamProvider<int>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.watchPendingCount();
});

final userByIdProvider = FutureProvider.autoDispose
    .family<ProfileModel, String>((ref, id) async {
      final adminService = ref.watch(adminServiceProvider);
      return await adminService.getUserById(id);
    });

// Locations
final locationsProvider = StreamProvider.autoDispose<List<LocationModel>>((
  ref,
) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.watchLocations();
});

final selectedLocationProvider = StateProvider<String?>((ref) => null);

// Books
class BookFilter {
  final String? genre;
  final bool availableOnly;
  final String? searchQuery;

  BookFilter({this.genre, this.availableOnly = false, this.searchQuery});

  BookFilter copyWith({
    String? genre,
    bool? availableOnly,
    String? searchQuery,
  }) {
    return BookFilter(
      genre: genre ?? this.genre,
      availableOnly: availableOnly ?? this.availableOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final booksFilterProvider = StateProvider<BookFilter>((ref) => BookFilter());

final booksProvider = StreamProvider.autoDispose<List<BookModel>>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  final filter = ref.watch(booksFilterProvider);
  
  // Watch locations and profile concurrently
  final locationsAsync = ref.watch(locationsProvider);
  final profileAsync = ref.watch(currentProfileProvider);
  
  final selectedLocation = ref.watch(selectedLocationProvider);

  final profile = profileAsync.value;
  final locations = locationsAsync.value;

  String? effectiveLocationId;
  if (profile != null) {
    if (profile.role == 'employee') {
      effectiveLocationId = profile.locationId;
    } else {
      effectiveLocationId = selectedLocation ?? profile.locationId;
    }
  }

  if (effectiveLocationId == null && locations != null && locations.isNotEmpty) {
    effectiveLocationId = locations.first.id;
  }

  if (effectiveLocationId == null) {
    return bookService.watchAllBooks().map((books) {
      return _filterBooks(books, filter);
    });
  }

  return bookService.watchBooks(effectiveLocationId).map((books) {
    return _filterBooks(books, filter);
  });
});

List<BookModel> _filterBooks(List<BookModel> books, BookFilter filter) {
  var filtered = books;
  
  // 1. Genre Filter
  if (filter.genre != null && filter.genre != 'All') {
    filtered = filtered.where((b) {
      final genres = List<String>.from(b.genre);
      return genres.contains(filter.genre);
    }).toList();
  }
  
  // 2. Availability Filter
  if (filter.availableOnly) {
    filtered = filtered.where((b) => b.availableCopies > 0).toList();
  }
  
  // 3. Search Query Filter
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    filtered = filtered.where((b) => 
      b.title.toLowerCase().contains(query) || 
      b.author.toLowerCase().contains(query)
    ).toList();
  }
  
  // 4. Sort descending by creation date
  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  return filtered;
}

final bookByIdProvider = FutureProvider.autoDispose.family<BookModel, String>((
  ref,
  id,
) async {
  final bookService = ref.watch(bookServiceProvider);
  return await bookService.getBookById(id);
});

// Borrows
final myActiveBorrowsProvider =
    FutureProvider.autoDispose<List<BorrowRecordModel>>((ref) async {
      final borrowService = ref.watch(borrowServiceProvider);
      return await borrowService.getMyActiveBorrows();
    });

final myHistoryProvider = FutureProvider.autoDispose<List<BorrowRecordModel>>((
  ref,
) async {
  final borrowService = ref.watch(borrowServiceProvider);
  return await borrowService.getMyHistory();
});

final recentBorrowsProvider =
    FutureProvider.autoDispose<List<BorrowRecordModel>>((ref) async {
      final borrowService = ref.watch(borrowServiceProvider);
      final locationId = ref.watch(selectedLocationProvider);
      return await borrowService.getAllRecords(
        locationId: locationId,
        limit: 10,
      );
    });


// Notifications
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      final supabase = ref.watch(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    });

final unreadNotifCountProvider = StreamProvider<int>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(0);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .map((list) => list.where((n) => n['is_read'] == false).length);
});
