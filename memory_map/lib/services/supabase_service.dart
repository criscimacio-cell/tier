import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  // AUTH
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password, String name) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async => await _client.auth.signOut();

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.memorymap://login-callback',
    );
  }

  Future<void> sendActivationEmail(String userId, String email, String name) async {
    await _client.functions.invoke('send-activation', body: {
      'userId': userId,
      'email': email,
      'name': name,
    });
  }

  // PROFILE
  Future<void> upsertProfile(String userId, String name, String username, String avatar, {bool isActivated = false}) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'username': username,
      'avatar': avatar,
      'is_activated': isActivated,
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return res;
  }

  Future<void> updateStreak(String userId, int streak) async {
    await _client.from('profiles').update({'streak': streak}).eq('id', userId);
  }

  // PINS
  Future<List<Map<String, dynamic>>> getPins(String userId) async {
    return await _client.from('pins').select().eq('user_id', userId).order('created_at', ascending: false);
  }

  Future<void> insertPin(MapPin pin) async {
    await _client.from('pins').insert({
      'id': pin.id,
      'user_id': pin.userId,
      'lat': pin.lat,
      'lng': pin.lng,
      'name': pin.name,
      'category': pin.category.index,
      'address': pin.address,
      'is_private': pin.isPrivate,
      'rating': pin.rating,
      'price_range': pin.priceRange.index,
    });
  }

  Future<void> updatePin(MapPin pin) async {
    await _client.from('pins').update({
      'name': pin.name,
      'category': pin.category.index,
      'address': pin.address,
      'is_private': pin.isPrivate,
      'rating': pin.rating,
      'price_range': pin.priceRange.index,
    }).eq('id', pin.id);
  }

  Future<void> deletePin(String pinId) async {
    await _client.from('pins').delete().eq('id', pinId);
  }

  // VISITS
  Future<List<Map<String, dynamic>>> getVisits(String pinId) async {
    return await _client.from('visits').select().eq('pin_id', pinId).order('visit_date', ascending: false);
  }

  Future<void> insertVisit(Visit visit, String pinId, String userId) async {
    await _client.from('visits').insert({
      'id': visit.id,
      'pin_id': pinId,
      'user_id': userId,
      'visit_date': visit.date.toIso8601String(),
      'review': visit.review,
      'mood': visit.mood.index,
      'journal_entry': visit.journalEntry,
    });
  }
}
