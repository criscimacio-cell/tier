import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class UserProvider extends ChangeNotifier {
  AppUser _user = AppUser(
    id: kCurrentUserId,
    name: '',
    username: '',
    avatarEmoji: '🌍',
    earnedBadgeIds: [],
  );

  final List<Friend> _friends = [];
  List<AppBadge> _badges = List.from(allBadges);

  bool _isLoggedIn = false;
  bool _onboardingComplete = false;

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
