import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

  // Search state
  bool _showSearch = false;
  List<Map<String, dynamic>> _searchResults = [];
  final _searchCtrl = TextEditingController();

  DateTime get _latestDate => DateTime.now();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
  }

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

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
    final res = await http.get(uri, headers: {'User-Agent': 'MemoryMap/1.0'});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() => _searchResults = data.cast<Map<String, dynamic>>());
    }
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
              // MAP
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
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
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

              // EMPTY STATE OVERLAY
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

              // FLOATING PILL HEADER
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
                            // Search toggle button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              onPressed: () {
                                setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _searchCtrl.clear();
                                    _searchResults = [];
                                  }
                                });
                              },
                              icon: Icon(
                                _showSearch ? Icons.close : Icons.search,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ),
                            // Notification bell
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

              // SEARCH BAR (below pill)
              Positioned(
                top: 52 + 56,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showSearch
                      ? Column(
                          key: const ValueKey('search_open'),
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search places...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                onChanged: (val) {
                                  
                                  _searchPlaces(val);
                                },
                              ),
                            ),
                            if (_searchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (ctx, i) {
                                    final result = _searchResults[i];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.place_outlined, color: Color(0xFF1A535C), size: 20),
                                      title: Text(
                                        result['display_name'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      onTap: () {
                                        final lat = double.parse(result['lat'] as String);
                                        final lon = double.parse(result['lon'] as String);
                                        _mapController.move(LatLng(lat, lon), 14);
                                        setState(() {
                                          _searchResults = [];
                                          _showSearch = false;
                                          _searchCtrl.clear();
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('search_closed')),
                ),
              ),

              // FRIENDS TOGGLE (below pill)
              Positioned(
                top: 52 + 56,
                right: 16,
                child: _showSearch
                    ? const SizedBox.shrink()
                    : GestureDetector(
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

              // BOTTOM FILTER + TIME SLIDER
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

          // FABs
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My location button
                FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A535C),
                  elevation: 3,
                  child: const Icon(Icons.my_location, size: 20),
                ),
                const SizedBox(height: 12),
                // Add pin button
                FloatingActionButton(
                  heroTag: 'addPin',
                  onPressed: _openLocationPicker,
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.add_location_alt, size: 26),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom pin marker widget - animated emoji bubble

class _PinMarker extends StatefulWidget {
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
  State<_PinMarker> createState() => _PinMarkerState();
}

class _PinMarkerState extends State<_PinMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double emojiFontSize = widget.isFriend ? 12 : 14;
    final double textFontSize = widget.isFriend ? 9 : 10;

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bubble
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.pin.category.emoji,
                    style: TextStyle(fontSize: emojiFontSize),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Text(
                      widget.pin.name,
                      style: TextStyle(
                        fontSize: textFontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Triangle tail
            CustomPaint(
              size: const Size(8, 5),
              painter: _PinTailPainter(color: widget.color),
            ),
          ],
        ),
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
