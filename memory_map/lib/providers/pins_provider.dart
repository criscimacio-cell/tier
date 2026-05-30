import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/storage.dart';

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

  Future<void> loadFromStorage() async {
    final stored = await PinsStorage.loadPins();
    _pins = stored; // empty list if first run — no defaults
    _isLoaded = true;
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> addPin(MapPin pin) async {
    _pins.add(pin);
    await PinsStorage.savePins(_pins);
    notifyListeners();
  }

  Future<void> addVisit(String pinId, Visit visit) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    final updatedVisits = List<Visit>.from(_pins[idx].visits)..add(visit);
    _pins[idx] = _pins[idx].copyWith(visits: updatedVisits);
    await PinsStorage.savePins(_pins);
    notifyListeners();
  }

  Future<void> removePin(String pinId) async {
    _pins.removeWhere((p) => p.id == pinId);
    await PinsStorage.savePins(_pins);
    notifyListeners();
  }

  Future<void> togglePrivacy(String pinId) async {
    final idx = _pins.indexWhere((p) => p.id == pinId);
    if (idx == -1) return;
    _pins[idx] = _pins[idx].copyWith(isPrivate: !_pins[idx].isPrivate);
    await PinsStorage.savePins(_pins);
    notifyListeners();
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
