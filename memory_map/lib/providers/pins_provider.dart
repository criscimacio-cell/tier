import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class PinsProvider extends ChangeNotifier {
  List<MapPin> _pins = [];
  Category? _categoryFilter;
  DateTime? _timeFilterStart;
  DateTime? _timeFilterEnd;
  bool _showFriendPins = false;
  DateTimeRange? _timeSliderRange;
  bool _isLoaded = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<MapPin> get pins => _pins;
  Category? get categoryFilter => _categoryFilter;
  DateTime? get timeFilterStart => _timeFilterStart;
  DateTime? get timeFilterEnd => _timeFilterEnd;
  bool get showFriendPins => _showFriendPins;
  DateTimeRange? get timeSliderRange => _timeSliderRange;
  bool get isLoaded => _isLoaded;

  List<MapPin> get filteredPins {
    var result = List<MapPin>.from(_pins);

    if (_categoryFilter != null) {
      result = result.where((p) => p.category == _categoryFilter).toList();
    }

    if (_timeSliderRange != null) {
      result = result.where((p) {
        final lastVisit = p.lastVisit;
        if (lastVisit == null) return false;
        return lastVisit.date.isAfter(_timeSliderRange!.start) &&
            lastVisit.date.isBefore(_timeSliderRange!.end);
      }).toList();
    } else if (_timeFilterStart != null && _timeFilterEnd != null) {
      result = result.where((p) {
        final lastVisit = p.lastVisit;
        if (lastVisit == null) return false;
        return lastVisit.date.isAfter(_timeFilterStart!) &&
            lastVisit.date.isBefore(_timeFilterEnd!);
      }).toList();
    }

    return result;
  }

  /// Pins that haven't been visited in >60 days (for revisit nudges)
  List<MapPin> get revisitNudges {
    final threshold = DateTime.now().subtract(const Duration(days: 60));
    return _pins.where((p) {
      final last = p.lastVisit;
      if (last == null) return false;
      return last.date.isBefore(threshold);
    }).toList();
  }

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> loadPins(String userId) async {
    try {
      final rows = await SupabaseService().getPins(userId);
      List<MapPin> loaded = [];
      for (final row in rows) {
        final visitRows = await SupabaseService().getVisits(row['id'] as String);
        final visits = visitRows.map((v) => Visit(
          id: v['id'] as String,
          date: DateTime.parse(v['visit_date'] as String),
          review: v['review'] ?? '',
          mood: Mood.values[(v['mood'] as int?) ?? 0],
          journalEntry: v['journal_entry'] ?? '',
          photoUrls: List<String>.from(v['photo_urls'] ?? []),
        )).toList();
        loaded.add(MapPin(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          lat: (row['lat'] as num).toDouble(),
          lng: (row['lng'] as num).toDouble(),
          name: row['name'] as String,
          category: Category.values[(row['category'] as int?) ?? 0],
          address: row['address'] ?? '',
          isPrivate: row['is_private'] ?? false,
          rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
          priceRange: PriceRange.values[(row['price_range'] as int?) ?? 0],
          visits: visits,
          createdAt: DateTime.parse(row['created_at'] as String),
        ));
      }
      _pins = loaded;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> addPin(MapPin pin) async {
    _pins.insert(0, pin);
    notifyListeners();
    await SupabaseService().insertPin(pin);
  }

  Future<void> addVisit(String pinId, Visit visit) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    final updated = _pins[idx].copyWith(visits: [..._pins[idx].visits, visit]);
    _pins[idx] = updated;
    notifyListeners();
    await SupabaseService().insertVisit(visit, pinId, _pins[idx].userId);
  }

  Future<void> removePin(String pinId) async {
    _pins.removeWhere((p) => p.id == pinId);
    notifyListeners();
    await SupabaseService().deletePin(pinId);
  }

  Future<void> togglePrivacy(String pinId) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    _pins[idx] = _pins[idx].copyWith(isPrivate: !_pins[idx].isPrivate);
    notifyListeners();
    await SupabaseService().updatePin(_pins[idx]);
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setCategoryFilter(Category? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setTimeFilter(DateTime? start, DateTime? end) {
    _timeFilterStart = start;
    _timeFilterEnd = end;
    notifyListeners();
  }

  void setTimeSliderRange(DateTimeRange? range) {
    _timeSliderRange = range;
    notifyListeners();
  }

  void toggleFriendPins() {
    _showFriendPins = !_showFriendPins;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = null;
    _timeFilterStart = null;
    _timeFilterEnd = null;
    _timeSliderRange = null;
    notifyListeners();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get totalVisits => _pins.fold(0, (sum, p) => sum + p.visits.length);

  Set<String> get visitedCities {
    final Set<String> cities = {};
    for (final pin in _pins) {
      final parts = pin.address.split(',');
      if (parts.length >= 2) {
        cities.add(parts[parts.length - 2].trim());
      }
    }
    return cities;
  }

  MapPin? pinById(String id) {
    try {
      return _pins.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
