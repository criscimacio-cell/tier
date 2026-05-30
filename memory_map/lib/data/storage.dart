import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class PinsStorage {
  static const String _pinsKey = 'memory_map_pins';

  static Future<List<MapPin>> loadPins() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_pinsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => MapPin.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePins(List<MapPin> pins) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(pins.map((p) => p.toJson()).toList());
    await prefs.setString(_pinsKey, encoded);
  }

  static Future<void> clearPins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinsKey);
  }
}
