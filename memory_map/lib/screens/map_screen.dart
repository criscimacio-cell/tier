import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/time_slider.dart';
import 'add_pin_screen.dart';
import 'location_picker_screen.dart';
import 'pin_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(14.5547, 121.0244);
  final MapController _mapController = MapController();
  bool _showTimeSlider = false;

  DateTime get _latestDate => DateTime.now();

  Future<void> _openLocationPicker() async {
    final location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (location != null && mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (ctx, sc) => AddPinScreen(initialLocation: location),
        ),
      );
    }
  }

  void _showPinDetail(MapPin pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, sc) => PinDetailSheet(pin: pin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PinsProvider, UserProvider>(
      builder: (context, pinsP, userP, _) {
        final displayedPins = pinsP.filteredPins;
        final friendPins =
            pinsP.showFriendPins ? userP.allFriendPins : <MapPin>[];
        final isEmpty = pinsP.pins.isEmpty;

        return Scaffold(
          body: Stack(
            children: [
              // ── MAP ──────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 13.0,
                  minZoom: 10,
                  maxZoom: 18,
                  onTap: null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.memory_map',
                  ),

                  // Friend pins layer
                  if (friendPins.isNotEmpty && userP.friends.isNotEmpty)
                    MarkerLayer(
                      markers: friendPins
                          .map((pin) {
                            final friend = userP.friends.cast<Friend?>().firstWhere(
                              (f) => f!.id == pin.userId,
                              orElse: () => null,
                            );
                            if (friend == null) return null;
                            return Marker(
                              point: pin.latLng,
                              width: 48,
                              height: 56,
                              child: _PinMarker(
                                pin: pin,
                                color: friend.pinColor,
                                isFriend: true,
                                onTap: () => _showPinDetail(pin),
                              ),
                            );
                          })
                          .whereType<Marker>()
                          .toList(),
                    ),

                  // User pins layer
                  MarkerLayer(
                    markers: displayedPins.map((pin) {
                      return Marker(
                        point: pin.latLng,
                        width: 56,
                        height: 64,
                        child: _PinMarker(
                          pin: pin,
                          color: pin.category.color,
                          isFriend: false,
                          onTap: () => _showPinDetail(pin),
                        ),
                      );
                    }).toList(),
                  ),

                ],
              ),

              // ── EMPTY STATE OVERLAY ───────────────────────────────────────
              if (isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1628).withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '📍',
                          style: TextStyle(fontSize: 52),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your map is empty',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to drop your first memory',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── FLOATING PILL HEADER ──────────────────────────────────────
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 280,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1628).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 14),
                            const Text(
                              '🗺️',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'memorymap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              onPressed: () {},
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── FRIENDS TOGGLE (below pill) ───────────────────────────────
              Positioned(
                top: 52 + 56,
                right: 16,
                child: GestureDetector(
                  onTap: () => pinsP.toggleFriendPins(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: pinsP.showFriendPins
                          ? Colors.white
                          : const Color(0xFF0A1628).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: pinsP.showFriendPins
                              ? const Color(0xFF1A535C)
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Friends',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pinsP.showFriendPins
                                ? const Color(0xFF1A535C)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── BOTTOM FILTER + TIME SLIDER ───────────────────────────────
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Time slider
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showTimeSlider
                          ? TimeSliderWidget(
                              key: const ValueKey('slider'),
                              earliest: DateTime.now()
                                  .subtract(const Duration(days: 730)),
                              latest: _latestDate,
                              value: pinsP.timeSliderRange,
                              onChanged: (range) =>
                                  pinsP.setTimeSliderRange(range),
                            )
                          : const SizedBox.shrink(key: ValueKey('none')),
                    ),

                    // Category filter + time toggle
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CategoryFilterBar(
                              selected: pinsP.categoryFilter,
                              onSelected: (cat) =>
                                  pinsP.setCategoryFilter(cat),
                            ),
                          ),
                          // Time toggle button
                          GestureDetector(
                            onTap: () => setState(
                                () => _showTimeSlider = !_showTimeSlider),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _showTimeSlider
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.access_time,
                                size: 18,
                                color: _showTimeSlider
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),

          // ── FAB ─────────────────────────────────────────────────────────
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton(
              onPressed: _openLocationPicker,
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_location_alt, size: 26),
            ),
          ),
        );
      },
    );
  }
}

// ── Custom pin marker widget ──────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final MapPin pin;
  final Color color;
  final bool isFriend;
  final VoidCallback onTap;

  const _PinMarker({
    required this.pin,
    required this.color,
    required this.isFriend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            constraints: const BoxConstraints(maxWidth: 90),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${pin.category.emoji} ${pin.name}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Pin circle
          Container(
            width: isFriend ? 18 : 22,
            height: isFriend ? 18 : 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: pin.isPrivate
                ? const Icon(Icons.lock, size: 10, color: Colors.white)
                : null,
          ),
          // Tail
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTailPainter(color: color),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
