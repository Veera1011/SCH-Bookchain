import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/location_model.dart';

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // ── Pending Users ─────────────────────────────────────────────────────────
  Future<List<ProfileModel>> getPendingUsers({String? locationId}) async {
    // ✅ All .eq() filters BEFORE .order()
    var query = _supabase.from('profiles').select().eq('status', 'pending');

    if (locationId != null) {
      query = query.eq('location_id', locationId);
    }

    final data = await query.order('created_at', ascending: true);
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  // ── Active Users ──────────────────────────────────────────────────────────
  Future<List<ProfileModel>> getActiveUsers({String? locationId}) async {
    var query = _supabase.from('profiles').select().eq('status', 'active');

    if (locationId != null) {
      query = query.eq('location_id', locationId);
    }

    final data = await query.order('name', ascending: true);
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  // ── All Users ─────────────────────────────────────────────────────────────
  Future<List<ProfileModel>> getAllUsers({
    String? locationId,
    String? status,
  }) async {
    var query = _supabase.from('profiles').select();

    if (locationId != null) query = query.eq('location_id', locationId);
    if (status != null) query = query.eq('status', status);

    final data = await query.order('name', ascending: true);
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  // ── Get User By ID ────────────────────────────────────────────────────────
  Future<ProfileModel> getUserById(String id) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .single();
    return ProfileModel.fromJson(data);
  }

  // ── Approve User ──────────────────────────────────────────────────────────
  Future<void> approveUser(String userId) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    await _supabase
        .from('profiles')
        .update({
          'status': 'active',
          'verified_by': currentUserId,
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // ── Reject User ───────────────────────────────────────────────────────────
  Future<void> rejectUser(String userId, String reason) async {
    final currentUserId = _supabase.auth.currentUser!.id;

    await _supabase
        .from('profiles')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'verified_by': currentUserId,
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // ── Delete User ──────────────────────────────────────────────────────────
  Future<void> deleteUser(String userId) async {
    // This deletes the profile record. 
    // Note: To delete from auth.users, an Edge Function would be needed.
    // Deleting the profile prevents them from accessing app-specific data.
    await _supabase
        .from('profiles')
        .delete()
        .eq('id', userId);
  }

  // ── Update Role ───────────────────────────────────────────────────────────
  Future<void> updateUserRole(String userId, String newRole) async {
    await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  // ── Update Location ───────────────────────────────────────────────────────
  Future<void> updateUserLocation(String userId, String locationId) async {
    await _supabase.from('profiles').update({'location_id': locationId}).eq('id', userId);
  }

  // ── Pending Count (one-time) ──────────────────────────────────────────────
  Future<int> getPendingUsersCount() async {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('status', 'pending');
    return (response as List).length;
  }

  // ── Pending Count (realtime stream) ──────────────────────────────────────
  Stream<int> watchPendingCount() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map(
          (list) => list.where((item) => item['status'] == 'pending').length,
        );
    // ✅ Can't use .eq() on stream for this filter — filter in .map() instead
  }

  // ── Locations (realtime stream) ──────────────────────────────────────────
  Stream<List<LocationModel>> watchLocations() {
    return _supabase
        .from('locations')
        .stream(primaryKey: ['id'])
        .map((list) => list
            .where((item) => item['is_active'] == true)
            .map((json) => LocationModel.fromJson(json))
            .toList());
  }

  // ── Users (realtime streams) ──────────────────────────────────────────────
  Stream<List<ProfileModel>> watchPendingUsers({String? locationId}) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((list) {
          var filtered = list.where((item) => item['status'] == 'pending');
          if (locationId != null) {
            filtered = filtered.where((item) => item['location_id'] == locationId);
          }
          var users = filtered.map((json) => ProfileModel.fromJson(json)).toList();
          users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return users;
        });
  }

  Stream<List<ProfileModel>> watchActiveUsers({String? locationId}) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((list) {
          var filtered = list.where((item) => item['status'] == 'active');
          if (locationId != null) {
            filtered = filtered.where((item) => item['location_id'] == locationId);
          }
          var users = filtered.map((json) => ProfileModel.fromJson(json)).toList();
          users.sort((a, b) => a.name.compareTo(b.name));
          return users;
        });
  }

  Stream<List<ProfileModel>> watchAllUsers({String? locationId, String? status}) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((list) {
          Iterable<Map<String, dynamic>> filtered = list;
          if (locationId != null) {
            filtered = filtered.where((item) => item['location_id'] == locationId);
          }
          if (status != null) {
            filtered = filtered.where((item) => item['status'] == status);
          }
          var users = filtered.map((json) => ProfileModel.fromJson(json)).toList();
          users.sort((a, b) => a.name.compareTo(b.name));
          return users;
        });
  }

  // ── Locations CRUD ────────────────────────────────────────────────────────
  Future<List<LocationModel>> getLocations() async {
    final data = await _supabase
        .from('locations')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List).map((json) => LocationModel.fromJson(json)).toList();
  }

  Future<void> addLocation(String name, String city, String? address) async {
    await _supabase.from('locations').insert({
      'name': name,
      'city': city,
      'address': address,
      'is_active': true,
    });
  }

  Future<void> updateLocation(String id, String name, String city, String? address) async {
    await _supabase.from('locations').update({
      'name': name,
      'city': city,
      'address': address,
    }).eq('id', id);
  }

  Future<void> deleteLocation(String id) async {
    // Soft delete to preserve referential integrity in books/users
    await _supabase.from('locations').update({'is_active': false}).eq('id', id);
  }
}
