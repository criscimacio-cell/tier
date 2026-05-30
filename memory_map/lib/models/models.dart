import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum Category { cafe, restaurant, hiddenGem, park, bar, shop, other }
enum Mood { cozy, lively, romantic, productive, adventurous, peaceful }
enum PriceRange { budget, moderate, upscale, luxury }

extension CategoryExtension on Category {
  String get label {
    switch (this) {
      case Category.cafe: return 'Café';
      case Category.restaurant: return 'Restaurant';
      case Category.hiddenGem: return 'Hidden Gem';
      case Category.park: return 'Park';
      case Category.bar: return 'Bar';
      case Category.shop: return 'Shop';
      case Category.other: return 'Other';
    }
  }
  String get emoji {
    switch (this) {
      case Category.cafe: return '☕';
      case Category.restaurant: return '🍽️';
      case Category.hiddenGem: return '💎';
      case Category.park: return '🌿';
      case Category.bar: return '🍻';
      case Category.shop: return '🛍️';
      case Category.other: return '📍';
    }
  }
  Color get color {
    switch (this) {
      case Category.cafe: return const Color(0xFFD2691E);
      case Category.restaurant: return const Color(0xFFE74C3C);
      case Category.hiddenGem: return const Color(0xFF9B59B6);
      case Category.park: return const Color(0xFF27AE60);
      case Category.bar: return const Color(0xFFF39C12);
      case Category.shop: return const Color(0xFF2980B9);
      case Category.other: return const Color(0xFF7F8C8D);
    }
  }
}

extension MoodExtension on Mood {
  String get label {
    switch (this) {
      case Mood.cozy: return 'Cozy';
      case Mood.lively: return 'Lively';
      case Mood.romantic: return 'Romantic';
      case Mood.productive: return 'Productive';
      case Mood.adventurous: return 'Adventurous';
      case Mood.peaceful: return 'Peaceful';
    }
  }
  String get emoji {
    switch (this) {
      case Mood.cozy: return '🧣';
      case Mood.lively: return '🎉';
      case Mood.romantic: return '💝';
      case Mood.productive: return '💻';
      case Mood.adventurous: return '🏔️';
      case Mood.peaceful: return '🌸';
    }
  }
}

extension PriceRangeExtension on PriceRange {
  String get label {
    switch (this) {
      case PriceRange.budget: return '₱';
      case PriceRange.moderate: return '₱₱';
      case PriceRange.upscale: return '₱₱₱';
      case PriceRange.luxury: return '₱₱₱₱';
    }
  }
}

class Visit {
  final String id;
  final DateTime date;
  final String review;
  final Mood mood;
  final List<String> photoUrls;
  final String journalEntry;
  final List<String> taggedFriends;

  Visit({
    required this.id,
    required this.date,
    required this.review,
    required this.mood,
    this.photoUrls = const [],
    this.journalEntry = '',
    this.taggedFriends = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'review': review,
    'mood': mood.index,
    'photoUrls': photoUrls,
    'journalEntry': journalEntry,
    'taggedFriends': taggedFriends,
  };

  factory Visit.fromJson(Map<String, dynamic> j) => Visit(
    id: j['id'],
    date: DateTime.parse(j['date']),
    review: j['review'],
    mood: Mood.values[j['mood']],
    photoUrls: List<String>.from(j['photoUrls'] ?? []),
    journalEntry: j['journalEntry'] ?? '',
    taggedFriends: List<String>.from(j['taggedFriends'] ?? []),
  );
}

class MapPin {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final String name;
  final Category category;
  final String address;
  final bool isPrivate;
  final DateTime createdAt;
  final List<Visit> visits;
  final double rating;
  final PriceRange priceRange;
  final List<String> bestItems;

  MapPin({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.name,
    required this.category,
    required this.address,
    this.isPrivate = false,
    required this.createdAt,
    required this.visits,
    required this.rating,
    required this.priceRange,
    this.bestItems = const [],
  });

  LatLng get latLng => LatLng(lat, lng);

  Visit? get lastVisit {
    if (visits.isEmpty) return null;
    final sorted = List<Visit>.from(visits)..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'lat': lat,
    'lng': lng,
    'name': name,
    'category': category.index,
    'address': address,
    'isPrivate': isPrivate,
    'createdAt': createdAt.toIso8601String(),
    'visits': visits.map((v) => v.toJson()).toList(),
    'rating': rating,
    'priceRange': priceRange.index,
    'bestItems': bestItems,
  };

  factory MapPin.fromJson(Map<String, dynamic> j) => MapPin(
    id: j['id'],
    userId: j['userId'],
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    name: j['name'],
    category: Category.values[j['category']],
    address: j['address'],
    isPrivate: j['isPrivate'] ?? false,
    createdAt: DateTime.parse(j['createdAt']),
    visits: (j['visits'] as List? ?? []).map((v) => Visit.fromJson(v as Map<String, dynamic>)).toList(),
    rating: (j['rating'] as num).toDouble(),
    priceRange: PriceRange.values[j['priceRange']],
    bestItems: List<String>.from(j['bestItems'] ?? []),
  );

  MapPin copyWith({List<Visit>? visits, bool? isPrivate}) => MapPin(
    id: id, userId: userId, lat: lat, lng: lng, name: name,
    category: category, address: address, isPrivate: isPrivate ?? this.isPrivate,
    createdAt: createdAt, visits: visits ?? this.visits,
    rating: rating, priceRange: priceRange, bestItems: bestItems,
  );
}

class AppUser {
  final String id;
  final String name;
  final String username;
  final String avatarEmoji;
  final List<String> followingIds;
  final int streak;
  final DateTime? lastLoggedVisit;
  final List<String> earnedBadgeIds;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarEmoji,
    this.followingIds = const [],
    this.streak = 0,
    this.lastLoggedVisit,
    this.earnedBadgeIds = const [],
  });

  AppUser copyWith({
    int? streak,
    DateTime? lastLoggedVisit,
    List<String>? earnedBadgeIds,
    List<String>? followingIds,
  }) => AppUser(
    id: id,
    name: name,
    username: username,
    avatarEmoji: avatarEmoji,
    followingIds: followingIds ?? this.followingIds,
    streak: streak ?? this.streak,
    lastLoggedVisit: lastLoggedVisit ?? this.lastLoggedVisit,
    earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
  );
}

class Friend {
  final String id;
  final String name;
  final String username;
  final String avatarEmoji;
  final Color pinColor;
  final List<MapPin> pins;

  Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarEmoji,
    required this.pinColor,
    required this.pins,
  });
}

class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool earned;

  Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.earned,
  });
}
