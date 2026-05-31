import '../models/models.dart';

const String kCurrentUserId = 'user_local';

final List<AppBadge> allBadges = [
  AppBadge(id: 'badge_001', name: 'First Pin',        emoji: '📍', description: 'Dropped your first memory pin',          earned: false),
  AppBadge(id: 'badge_002', name: 'Café Hopper',      emoji: '☕', description: 'Visited 5 different cafés',              earned: false),
  AppBadge(id: 'badge_003', name: 'Night Owl',        emoji: '🦉', description: 'Logged 3 bar visits',                    earned: false),
  AppBadge(id: 'badge_004', name: 'Explorer',         emoji: '🧭', description: 'Pinned places in 3 different cities',   earned: false),
  AppBadge(id: 'badge_005', name: 'Memory Maker',     emoji: '📖', description: 'Logged 10 visits total',                earned: false),
  AppBadge(id: 'badge_006', name: 'Foodie',           emoji: '🍜', description: 'Pinned 5 restaurants',                  earned: false),
  AppBadge(id: 'badge_007', name: 'Park Ranger',      emoji: '🌿', description: 'Visited 3 parks',                       earned: false),
  AppBadge(id: 'badge_008', name: 'Hidden Gem Hunter',emoji: '💎', description: 'Found 3 hidden gems',                   earned: false),
  AppBadge(id: 'badge_009', name: 'Globetrotter',     emoji: '🌍', description: 'Pinned a place outside your home country', earned: false),
  AppBadge(id: 'badge_010', name: 'Streak Master',    emoji: '🔥', description: 'Maintained a 7-day logging streak',     earned: false),
  AppBadge(id: 'badge_011', name: 'Social Butterfly', emoji: '🦋', description: 'Added your first friend',               earned: false),
  AppBadge(id: 'badge_012', name: 'Chronicler',       emoji: '✍️', description: 'Wrote journal entries for 5 visits',    earned: false),
];
