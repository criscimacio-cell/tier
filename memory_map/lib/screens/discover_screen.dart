import 'dart:ui';
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
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              // ── Frosted pill header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _DiscoverHeader(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  onSearchClear: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
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
                        'Vibe',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.5,
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
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel ? cat.color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? cat.color
                                        : Colors.grey.shade400,
                                    width: sel ? 0 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  '${cat.emoji} ${cat.label}',
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.5,
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
                                    horizontal: 18, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF0F172A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF0F172A)
                                        : Colors.grey.shade400,
                                    width: sel ? 0 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  pr.label,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w400,
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
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${nudges.length}',
                            style: const TextStyle(
                              color: Color(0xFFF43F5E),
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xFFF43F5E),
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
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
                                    color: Color(0xFFF43F5E),
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
              if (userP.friends.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text(
                      '🌟 Friend Picks',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              color: friend.pinColor.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.avatarEmoji,
                                        style: const TextStyle(fontSize: 16),
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
              ],

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
                            color: Color(0xFF1E293B),
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
                      final friend = userP.friends.cast<Friend?>().firstWhere(
                        (f) => f!.id == pin.userId,
                        orElse: () => null,
                      );
                      if (friend == null) return const SizedBox.shrink();
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

              // ── Empty state (no pins, no friends, no search) ───────────
              if (nudges.isEmpty &&
                  userP.friends.isEmpty &&
                  _searchQuery.isEmpty &&
                  _vibeFilter == null &&
                  _budgetFilter == null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      children: [
                        const Text('🗺️', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nothing to discover yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drop your first pin on the map to start building your memory collection.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

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
                        color: Color(0xFF1E293B),
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

// ── Frosted discover header ───────────────────────────────────────────────────

class _DiscoverHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  const _DiscoverHeader({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'explore.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'your world, your discoveries.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.12),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search places, areas...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withValues(alpha: 0.6)),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.white.withValues(alpha: 0.6)),
                                onPressed: onSearchClear,
                              )
                            : null,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                        border: InputBorder.none,
                      ),
                      cursorColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border(
            left: BorderSide(color: Color(0xFFF43F5E), width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: pin.category.color.withValues(alpha: 0.12),
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
                      color: friend.pinColor.withValues(alpha: 0.12),
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
      ),
    );
  }
}
