import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../services/supabase_service.dart';

class UserProvider extends ChangeNotifier {
  AppUser _user = AppUser(
    id: '',
    name: '',
    username: '',
    avatarEmoji: '🌍',
    earnedBadgeIds: [],
  );

  final List<Friend> _friends = [];
  List<AppBadge> _badges = List.from(allBadges);

  bool _isLoggedIn = false;
  bool _onboardingComplete = false;
  late final StreamSubscription<AuthState> _authSub;

  UserProvider() {
    _authSub = SupabaseService().authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && !_isLoggedIn && state.session != null) {
        _loadUserFromSession(state.session!.user);
      } else if (state.event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        _onboardingComplete = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  AppUser get user => _user;
  List<Friend> get friends => _friends;
  List<AppBadge> get badges => _badges;
  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingComplete => _onboardingComplete;

  List<AppBadge> get earnedBadges =>
      _badges.where((b) => _user.earnedBadgeIds.contains(b.id)).toList();

  List<MapPin> get allFriendPins =>
      _friends.expand((f) => f.pins).toList();

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Legacy login method (kept for compatibility, delegates to signIn/signUp).
  void login(String name, String email) {
    _user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: '@${name.toLowerCase().replaceAll(' ', '.')}',
      avatarEmoji: _pickEmoji(name),
      streak: 0,
      earnedBadgeIds: [],
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Returns null = logged in, '__confirm__' = activation email sent, else error message.
  Future<String?> signUp(String name, String email, String password) async {
    try {
      final res = await SupabaseService().signUp(email, password, name);
      if (res.user == null) return 'Sign up failed';
      final userId = res.user!.id;
      final avatar = _pickEmoji(name);
      final username = '@${name.toLowerCase().replaceAll(' ', '.')}';
      // Create profile as inactive — activated by clicking the email link
      await SupabaseService().upsertProfile(userId, name, username, avatar, isActivated: false);
      // Send activation email via our custom Edge Function, then sign out
      await SupabaseService().sendActivationEmail(userId, email, name);
      await SupabaseService().signOut();
      return '__confirm__';
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns null = logged in, '__not_activated__' = needs activation, else error.
  Future<String?> signIn(String email, String password) async {
    try {
      final res = await SupabaseService().signIn(email, password);
      if (res.user == null) return 'Sign in failed';
      final userId = res.user!.id;
      final profile = await SupabaseService().getProfile(userId);
      if (profile == null || profile['is_activated'] != true) {
        await SupabaseService().signOut();
        return '__not_activated__';
      }
      _user = AppUser(
        id: userId,
        name: profile['name'] ?? email.split('@').first,
        username: profile['username'] ?? '@user',
        avatarEmoji: profile['avatar'] ?? '🌍',
        streak: profile['streak'] ?? 0,
        earnedBadgeIds: [],
      );
      _isLoggedIn = true;
      _onboardingComplete = true;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _loadUserFromSession(User supabaseUser) async {
    try {
      var profile = await SupabaseService().getProfile(supabaseUser.id);
      // Google sign-in: create profile on first login (auto-activated)
      if (profile == null) {
        final name = supabaseUser.userMetadata?['full_name'] as String? ??
                     supabaseUser.userMetadata?['name'] as String? ??
                     supabaseUser.email?.split('@').first ?? 'User';
        final avatar = _pickEmoji(name);
        final username = '@${name.toLowerCase().replaceAll(' ', '.')}';
        try { await SupabaseService().upsertProfile(supabaseUser.id, name, username, avatar, isActivated: true); } catch (_) {}
        profile = {'name': name, 'username': username, 'avatar': avatar, 'streak': 0, 'is_activated': true};
      }
      // Block unactivated accounts (email signups awaiting activation)
      if (profile['is_activated'] != true) {
        try { await SupabaseService().signOut(); } catch (_) {}
        return;
      }
      _user = AppUser(
        id: supabaseUser.id,
        name: profile['name'] ?? '',
        username: profile['username'] ?? '',
        avatarEmoji: profile['avatar'] ?? '🌍',
        streak: profile['streak'] ?? 0,
        earnedBadgeIds: [],
      );
      _isLoggedIn = true;
      _onboardingComplete = true;
      notifyListeners();
    } catch (_) {}
  }

  void restoreSession(User supabaseUser) {
    if (!_isLoggedIn) _loadUserFromSession(supabaseUser);
  }

  Future<String?> signInWithGoogle() async {
    try {
      await SupabaseService().signInWithGoogle();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await SupabaseService().signOut();
    _isLoggedIn = false;
    _onboardingComplete = false;
    _user = AppUser(
      id: '',
      name: '',
      username: '',
      avatarEmoji: '🌍',
      earnedBadgeIds: [],
    );
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }

  String _pickEmoji(String name) {
    const emojis = ['🦊', '🐻', '🦁', '🐨', '🦄', '🐸', '🦋', '🌻', '🍀', '🌙', '🎯', '🗺️'];
    return emojis[name.codeUnits.fold(0, (a, b) => a + b) % emojis.length];
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  void updateStreak() {
    final now = DateTime.now();
    final last = _user.lastLoggedVisit;
    if (last == null) {
      _user = _user.copyWith(streak: 1, lastLoggedVisit: now);
      notifyListeners();
      return;
    }
    final daysSinceLast = now.difference(last).inDays;
    if (daysSinceLast == 0) return;
    _user = daysSinceLast == 1
        ? _user.copyWith(streak: _user.streak + 1, lastLoggedVisit: now)
        : _user.copyWith(streak: 1, lastLoggedVisit: now);
    notifyListeners();
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  void awardBadge(String badgeId) {
    if (_user.earnedBadgeIds.contains(badgeId)) return;
    final updated = List<String>.from(_user.earnedBadgeIds)..add(badgeId);
    _user = _user.copyWith(earnedBadgeIds: updated);
    _badges = _badges.map((b) => b.id == badgeId
        ? AppBadge(id: b.id, name: b.name, emoji: b.emoji, description: b.description, earned: true)
        : b).toList();
    notifyListeners();
  }

  void checkAndAwardBadges(int totalPins, int totalVisits) {
    if (totalPins >= 1) awardBadge('badge_001');
    if (totalVisits >= 10) awardBadge('badge_005');
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  Friend? friendById(String id) {
    try {
      return _friends.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> compareWithFriend(String friendId, List<MapPin> myPins) {
    final friend = friendById(friendId);
    if (friend == null) return {};
    final myNames = myPins.map((p) => p.name.toLowerCase()).toSet();
    final friendNames = friend.pins.map((p) => p.name.toLowerCase()).toSet();
    return {
      'overlapCount': myNames.intersection(friendNames).length,
      'onlyMine': myPins.where((p) => !friendNames.contains(p.name.toLowerCase())).toList(),
      'onlyFriend': friend.pins.where((p) => !myNames.contains(p.name.toLowerCase())).toList(),
    };
  }
}
