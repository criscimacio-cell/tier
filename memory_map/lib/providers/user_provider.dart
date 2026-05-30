import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class UserProvider extends ChangeNotifier {
  AppUser _user = AppUser(
    id: kCurrentUserId,
    name: 'Alex Mendoza',
    username: '@alex.memorymap',
    avatarEmoji: '🧳',
    followingIds: ['friend_001', 'friend_002', 'friend_003'],
    streak: 12,
    lastLoggedVisit: DateTime.now().subtract(const Duration(days: 1)),
    earnedBadgeIds: [
      'badge_001',
      'badge_002',
      'badge_003',
      'badge_004',
      'badge_005',
      'badge_006',
    ],
  );

  final List<Friend> _friends = List.from(mockFriends);
  List<AppBadge> _badges = List.from(mockBadges);

  bool _isLoggedIn = false;
  bool _onboardingComplete = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  AppUser get user => _user;
  List<Friend> get friends => _friends;
  List<AppBadge> get badges => _badges;
  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingComplete => _onboardingComplete;

  List<AppBadge> get earnedBadges =>
      _badges.where((b) => _user.earnedBadgeIds.contains(b.id)).toList();

  List<AppBadge> get unearnedBadges =>
      _badges.where((b) => !_user.earnedBadgeIds.contains(b.id)).toList();

  // Returns all friend pins combined
  List<MapPin> get allFriendPins =>
      _friends.expand((f) => f.pins).toList();

  // ── Auth / Onboarding ─────────────────────────────────────────────────────

  void login(String name, String username) {
    _user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: '@${username.toLowerCase().replaceAll(' ', '.')}',
      avatarEmoji: _randomEmoji(),
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

  String _randomEmoji() {
    const emojis = ['🦊', '🐻', '🦁', '🐨', '🦄', '🐸', '🦋', '🌻', '🍀', '🌙'];
    return emojis[DateTime.now().millisecond % emojis.length];
  }

  // ── Streak ───────────────────────────────────────────────────────────────

  void updateStreak() {
    final now = DateTime.now();
    final last = _user.lastLoggedVisit;

    if (last == null) {
      _user = _user.copyWith(streak: 1, lastLoggedVisit: now);
      notifyListeners();
      return;
    }

    final daysSinceLast = now.difference(last).inDays;

    if (daysSinceLast == 0) {
      // Same day — no change
      return;
    } else if (daysSinceLast == 1) {
      // Consecutive day
      _user = _user.copyWith(streak: _user.streak + 1, lastLoggedVisit: now);
    } else {
      // Streak broken
      _user = _user.copyWith(streak: 1, lastLoggedVisit: now);
    }
    notifyListeners();
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  void awardBadge(String badgeId) {
    if (_user.earnedBadgeIds.contains(badgeId)) return;
    final updated = List<String>.from(_user.earnedBadgeIds)..add(badgeId);
    _user = _user.copyWith(earnedBadgeIds: updated);

    // Also update the badge list to mark as earned
    _badges = _badges.map((b) {
      if (b.id == badgeId) {
        return AppBadge(
          id: b.id,
          name: b.name,
          emoji: b.emoji,
          description: b.description,
          earned: true,
        );
      }
      return b;
    }).toList();

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

  // ── Map overlap analysis ──────────────────────────────────────────────────

  Map<String, dynamic> compareWithFriend(String friendId, List<MapPin> myPins) {
    final friend = friendById(friendId);
    if (friend == null) return {};

    final myNames = myPins.map((p) => p.name.toLowerCase()).toSet();
    final friendNames = friend.pins.map((p) => p.name.toLowerCase()).toSet();
    final overlap = myNames.intersection(friendNames);

    final onlyMine = myPins.where((p) => !friendNames.contains(p.name.toLowerCase())).toList();
    final onlyFriends = friend.pins.where((p) => !myNames.contains(p.name.toLowerCase())).toList();

    return {
      'overlapCount': overlap.length,
      'onlyMine': onlyMine,
      'onlyFriend': onlyFriends,
      'friendName': friend.name,
    };
  }
}
