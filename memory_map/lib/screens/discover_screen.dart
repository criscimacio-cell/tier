import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/star_rating.dart';
import '../widgets/pin_card.dart';
import 'pin_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Category? _vibeFilter;
  PriceRange? _budgetFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapPin> _applyFilters(List<MapPin> pins) {
    var result = pins;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_vibeFilter != null) {
      result = result.where((p) => p.category == _vibeFilter).toList();
    }
    if (_budgetFilter != null) {
      result = result.where((p) => p.priceRange == _budgetFilter).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PinsProvider, UserProvider>(
      builder: (ctx, pinsP, userP, _) {
        final nudges = pinsP.revisitNudges;
        final friendPins = userP.allFriendPins;
        final myPinNames =
            pinsP.pins.map((p) => p.name.toLowerCase()).toSet();
        final untried = friendPins
            .where((p) => !myPinNames.contains(p.name.toLowerCase()))
            .toList();

        final filteredPins = _applyFilters(pinsP.pins);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F3E9),
          body: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: const Color(0xFF1A535C),
                pinned: true,
                title: const Text(
                  'Discover',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search places, areas...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Vibe',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1A535C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: Category.values.map((cat) {
                            final sel = _vibeFilter == cat;
                            return GestureDetector(
                              onTap: () => setState(() =>
                                  _vibeFilter = sel ? null : cat),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? cat.color
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: sel
                                        ? cat.color
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  '${cat.emoji} ${cat.label}',
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Filter by Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1A535C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: PriceRange.values.map((pr) {
                            final sel = _budgetFilter == pr;
                            return GestureDetector(
                              onTap: () => setState(() =>
                                  _budgetFilter = sel ? null : pr),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF1A535C)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF1A535C)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  pr.label,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Revisit Nudges ─────────────────────────────────────────
              if (nudges.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          '👋 Time to Revisit',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${nudges.length}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: nudges.length,
                      itemBuilder: (_, i) {
                        final pin = nudges[i];
                        final daysSince = pin.lastVisit != null
                            ? DateTime.now()
                                .difference(pin.lastVisit!.date)
                                .inDays
                            : 0;
                        return GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.82,
                              minChildSize: 0.5,
                              maxChildSize: 0.97,
                              builder: (c, s) =>
                                  PinDetailSheet(pin: pin),
                            ),
                          ),
                          child: Container(
                            width: 145,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pin.category.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const Spacer(),
                                Text(
                                  pin.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$daysSince days ago',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ── Friend Recommendations ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: const Text(
                    '🌟 Friend Picks',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: userP.friends.length,
                    itemBuilder: (_, i) {
                      final friend = userP.friends[i];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: friend.pinColor.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: friend.pinColor
                                        .withOpacity(0.15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      friend.avatarEmoji,
                                      style: const TextStyle(
                                          fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    friend.name.split(' ').first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '${friend.pins.length} places',
                              style: TextStyle(
                                color: friend.pinColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              friend.username,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Places you haven't tried ───────────────────────────────
              if (untried.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          '✨ Unexplored',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Friend recommendations',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final pin = untried[i];
                      final friend = userP.friends.firstWhere(
                        (f) => f.id == pin.userId,
                        orElse: () => userP.friends.first,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: _UntriedPinCard(
                          pin: pin,
                          friend: friend,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.82,
                              minChildSize: 0.5,
                              maxChildSize: 0.97,
                              builder: (c, s) =>
                                  PinDetailSheet(pin: pin),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: untried.length,
                  ),
                ),
              ],

              // ── Search results / All pins ──────────────────────────────
              if (_searchQuery.isNotEmpty ||
                  _vibeFilter != null ||
                  _budgetFilter != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text(
                      '${filteredPins.length} result${filteredPins.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: PinCard(
                        pin: filteredPins[i],
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.82,
                            minChildSize: 0.5,
                            maxChildSize: 0.97,
                            builder: (c, s) =>
                                PinDetailSheet(pin: filteredPins[i]),
                          ),
                        ),
                      ),
                    ),
                    childCount: filteredPins.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _UntriedPinCard extends StatelessWidget {
  final MapPin pin;
  final Friend friend;
  final VoidCallback onTap;

  const _UntriedPinCard({
    required this.pin,
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: friend.pinColor.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: pin.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  pin.category.emoji,
                  style: const TextStyle(fontSize: 22),
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
                  Text(
                    pin.address,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StarRating(rating: pin.rating, size: 13),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: friend.pinColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    friend.avatarEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pin.priceRange.label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
