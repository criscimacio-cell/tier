import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/badge_card.dart';
import '../models/models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PinsProvider, UserProvider>(
      builder: (ctx, pinsP, userP, _) {
        final user = userP.user;
        final pins = pinsP.pins;
        final totalVisits = pinsP.totalVisits;
        final cities = pinsP.visitedCities;
        final badges = userP.badges;

        // Recent activity list
        final allVisits = pins
            .expand((p) => p.visits.map((v) => (pin: p, visit: v)))
            .toList()
          ..sort((a, b) => b.visit.date.compareTo(a.visit.date));
        final recentActivity = allVisits.take(5).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F3E9),
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                backgroundColor: const Color(0xFF1A535C),
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A535C),
                          Color(0xFF0D3B45),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.avatarEmoji,
                                      style: const TextStyle(fontSize: 36),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        user.username,
                                        style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B6B)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFFF6B6B)
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          '🔥 ${user.streak} day streak',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _StatBox(
                          value: '${pins.length}', label: 'Places'),
                      _Divider(),
                      _StatBox(
                          value: '$totalVisits', label: 'Visits'),
                      _Divider(),
                      _StatBox(
                          value: '${cities.length}', label: 'Cities'),
                      _Divider(),
                      _StatBox(value: '1', label: 'Country'),
                    ],
                  ),
                ),
              ),

              // Badges section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Explorer Badges',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${userP.earnedBadges.length}/${badges.length}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => BadgeCard(badge: badges[i]),
                    childCount: badges.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                ),
              ),

              // City completion
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Area Coverage',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressBar(
                        label: 'Cafés in BGC',
                        emoji: '☕',
                        progress: 0.34,
                        color: const Color(0xFFD2691E),
                      ),
                      const SizedBox(height: 10),
                      _ProgressBar(
                        label: 'Restaurants in Makati',
                        emoji: '🍽️',
                        progress: 0.55,
                        color: const Color(0xFFE74C3C),
                      ),
                      const SizedBox(height: 10),
                      _ProgressBar(
                        label: 'Bars in Poblacion',
                        emoji: '🍻',
                        progress: 0.28,
                        color: const Color(0xFFF39C12),
                      ),
                      const SizedBox(height: 10),
                      _ProgressBar(
                        label: 'Parks in QC',
                        emoji: '🌿',
                        progress: 0.18,
                        color: const Color(0xFF27AE60),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = recentActivity[i];
                    return _ActivityItem(
                      pin: item.pin,
                      visit: item.visit,
                    );
                  },
                  childCount: recentActivity.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Color(0xFF1A535C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade200,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final String emoji;
  final double progress;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.emoji,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final MapPin pin;
  final Visit visit;

  const _ActivityItem({required this.pin, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pin.category.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                pin.category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visit.review.isNotEmpty
                      ? visit.review
                      : 'Visited this place',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM d').format(visit.date),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                visit.mood.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
