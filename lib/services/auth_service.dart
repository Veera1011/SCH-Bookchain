import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
          
      return ProfileModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<ProfileModel> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Login failed');
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
        
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> signUp(
    String email, 
    String password, 
    String name, 
    String locationId, 
    String? department
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      // emailRedirectTo is not set to avoid unnecessary redirect flows
    );
    
    if (response.user == null) {
      throw Exception('Registration failed');
    }

    final profileData = {
      'id': response.user!.id,
      'name': name,
      'email': email,
      'location_id': locationId,
      'department': department,
      'status': 'pending',
      'role': 'employee',
      'points': 0,
      'reading_goal': 12,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _supabase.from('profiles').insert(profileData).select().single();
    return ProfileModel.fromJson(result);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
