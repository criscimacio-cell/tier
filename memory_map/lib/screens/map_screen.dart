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
import 'pin_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(14.5547, 121.0244);
  final MapController _mapController = MapController();
  LatLng? _pendingPinLocation;
  bool _showTimeSlider = false;
  bool _addingPin = false;

  DateTime get _latestDate => DateTime.now();

  void _onMapTap(TapPosition tapPos, LatLng point) {
    if (_addingPin) {
      setState(() {
        _pendingPinLocation = point;
        _addingPin = false;
      });
      _showAddPinSheet(point);
    }
  }

  Future<void> _showAddPinSheet(LatLng location) async {
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
    setState(() {
      _pendingPinLocation = null;
    });
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
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.memory_map',
                  ),

                  // Friend pins layer
                  if (friendPins.isNotEmpty)
                    MarkerLayer(
                      markers: friendPins.map((pin) {
                        final friend = userP.friends.firstWhere(
                          (f) => f.id == pin.userId,
                          orElse: () => userP.friends.first,
                        );
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
                      }).toList(),
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

                  // Pending pin indicator
                  if (_pendingPinLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pendingPinLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.add_location,
                            color: Color(0xFFFF6B6B),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── TOP GRADIENT OVERLAY ──────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120 + MediaQuery.of(context).padding.top,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC1A535C),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text(
                            userP.user.avatarEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'My Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${displayedPins.length} places',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Notification bell
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // Friend layer toggle
                      GestureDetector(
                        onTap: () => pinsP.toggleFriendPins(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: pinsP.showFriendPins
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
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
                    ],
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
                              earliest: DateTime(2023),
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
                            Colors.black.withOpacity(0.35),
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
                                    : Colors.white.withOpacity(0.85),
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

              // ── ADD PIN MODE BANNER ───────────────────────────────────────
              if (_addingPin)
                Positioned(
                  top: 120 + MediaQuery.of(context).padding.top,
                  left: 30,
                  right: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Tap on the map to place your pin',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _addingPin = false),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── FAB ─────────────────────────────────────────────────────────
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: FloatingActionButton(
              onPressed: () {
                if (_addingPin) {
                  setState(() => _addingPin = false);
                } else {
                  setState(() => _addingPin = true);
                }
              },
              backgroundColor: _addingPin
                  ? Colors.grey.shade600
                  : const Color(0xFFFF6B6B),
              elevation: 4,
              child: Icon(
                _addingPin ? Icons.close : Icons.add_location_alt,
                color: Colors.white,
                size: 26,
              ),
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
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
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
                  color: color.withOpacity(0.4),
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
