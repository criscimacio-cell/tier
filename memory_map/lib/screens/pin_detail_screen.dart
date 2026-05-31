import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../widgets/star_rating.dart';
import '../widgets/mood_chip.dart';
import 'add_visit_screen.dart';

class PinDetailSheet extends StatelessWidget {
  final MapPin pin;

  const PinDetailSheet({super.key, required this.pin});

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()} months ago';
    return '${(diff.inDays / 365).round()} years ago';
  }

  /// Generate a rich gradient for each photo card using the category color.
  List<Color> _gradientForIndex(int i) {
    final base = pin.category.color;
    // Darken the base color for a gradient feel
    final darkened = Color.fromARGB(
      ((base.a * 255.0).round() & 0xff),
      ((base.r * 255.0 * 0.55).round() & 0xff),
      ((base.g * 255.0 * 0.55).round() & 0xff),
      ((base.b * 255.0 * 0.55).round() & 0xff),
    );
    // Alternate slight hue variations to give each slide a unique feel
    switch (i % 4) {
      case 0:
        return [base.withValues(alpha: 0.85), darkened];
      case 1:
        return [darkened, base.withValues(alpha: 0.7)];
      case 2:
        return [base.withValues(alpha: 0.6), darkened.withValues(alpha: 0.9)];
      case 3:
      default:
        return [darkened.withValues(alpha: 0.8), base.withValues(alpha: 0.75)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedVisits = List<Visit>.from(pin.visits)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Use sortedVisits count for carousel, fall back to 4 min slides
    final carouselCount = sortedVisits.isEmpty ? 1 : sortedVisits.length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Photo carousel
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller:
                            PageController(viewportFraction: 0.88),
                        itemCount: carouselCount,
                        itemBuilder: (_, i) {
                          final visit =
                              i < sortedVisits.length ? sortedVisits[i] : null;
                          final gradientColors = _gradientForIndex(i);

                          final hasPhoto = visit != null &&
                              visit.photoUrls.isNotEmpty;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Photo or gradient background
                                  if (hasPhoto)
                                    Image.network(
                                      visit.photoUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: gradientColors,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(pin.category.emoji,
                                              style: const TextStyle(
                                                  fontSize: 52)),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradientColors,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        pin.category.emoji,
                                        style: const TextStyle(fontSize: 52),
                                      ),
                                    ),
                                  ),

                                  // Visit date + mood overlay (top-left)
                                  if (visit != null)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  visit.mood.emoji,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  DateFormat('MMM d, yyyy')
                                                      .format(visit.date),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Review snippet overlay (bottom)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 32, 14, 14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.6),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        visit != null &&
                                                visit.review.isNotEmpty
                                            ? visit.review
                                            : '${pin.category.emoji} ${pin.name}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                ),

                // Main content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + private badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                pin.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            if (pin.isPrivate)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 8, top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B59B6)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock,
                                        size: 12,
                                        color: Color(0xFF9B59B6)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Private',
                                      style: TextStyle(
                                        color: Color(0xFF9B59B6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Category chip + address
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    pin.category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(pin.category.emoji,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    pin.category.label,
                                    style: TextStyle(
                                      color: pin.category.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pin.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Rating + price
                        Row(
                          children: [
                            StarRating(rating: pin.rating),
                            const SizedBox(width: 8),
                            Text(
                              pin.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Text(
                                pin.priceRange.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Visit stats row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A535C).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                value: '${pin.visits.length}',
                                label: 'visits',
                                icon: Icons.place,
                              ),
                              Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.grey.shade300),
                              _StatItem(
                                value: pin.lastVisit != null
                                    ? _relativeTime(pin.lastVisit!.date)
                                    : 'Never',
                                label: 'last visit',
                                icon: Icons.access_time,
                              ),
                              if (pin.lastVisit != null) ...[
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: Colors.grey.shade300),
                                _StatItem(
                                  value: pin.lastVisit!.mood.emoji,
                                  label: pin.lastVisit!.mood.label,
                                  icon: null,
                                  isEmoji: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Best items
                        if (pin.bestItems.isNotEmpty) ...[
                          const Text(
                            'Must Try',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pin.bestItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3E9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFD2691E)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  pin.bestItems[i],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFD2691E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Visit history
                        Row(
                          children: [
                            const Text(
                              'Visit History',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${sortedVisits.length} visit${sortedVisits.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Visit cards
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final visit = sortedVisits[i];
                      return _VisitCard(visit: visit);
                    },
                    childCount: sortedVisits.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Privacy toggle
                Consumer<PinsProvider>(
                  builder: (ctx, pinsP, _) {
                    final currentPin =
                        pinsP.pinById(pin.id) ?? pin;
                    return OutlinedButton.icon(
                      onPressed: () => pinsP.togglePrivacy(pin.id),
                      icon: Icon(
                        currentPin.isPrivate
                            ? Icons.lock
                            : Icons.lock_open,
                        size: 16,
                        color: const Color(0xFF9B59B6),
                      ),
                      label: Text(
                        currentPin.isPrivate ? 'Private' : 'Public',
                        style: const TextStyle(color: Color(0xFF9B59B6)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF9B59B6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.92,
                          minChildSize: 0.5,
                          maxChildSize: 0.97,
                          builder: (ctx, sc) => AddVisitScreen(
                            pinId: pin.id,
                            pinName: pin.name,
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Log New Visit',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final bool isEmoji;

  const _StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isEmoji)
          Text(value, style: const TextStyle(fontSize: 22))
        else
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1A535C),
            ),
          ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(visit.date),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A535C),
                ),
              ),
              const SizedBox(width: 8),
              MoodChip(mood: visit.mood, compact: true),
            ],
          ),
          if (visit.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              visit.review,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (visit.journalEntry.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    visit.journalEntry,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (visit.taggedFriends.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'with ${visit.taggedFriends.length} friend${visit.taggedFriends.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
