import 'package:json_annotation/json_annotation.dart';

part 'place.g.dart';

@JsonSerializable()
class Place {
  final String id;
  final String name;
  final String description;
  final String category;
  final PlaceLocation location;
  final List<String> images;
  final double rating;
  final List<Review> reviews;
  final OpeningHours openingHours;
  final Contact contact;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final List<String> categories;
  final int priceRange;
  final double popularityScore;
  final DateTime lastUpdated;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.images,
    required this.rating,
    required this.reviews,
    required this.openingHours,
    required this.contact,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    required this.categories,
    required this.priceRange,
    required this.popularityScore,
    required this.lastUpdated,
  });

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceToJson(this);

  double get latitude => location.latitude;
  double get longitude => location.longitude;
  int get reviewCount => reviews.length;

  Place copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    PlaceLocation? location,
    List<String>? images,
    double? rating,
    List<Review>? reviews,
    OpeningHours? openingHours,
    Contact? contact,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    List<String>? categories,
    int? priceRange,
    double? popularityScore,
    DateTime? lastUpdated,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      openingHours: openingHours ?? this.openingHours,
      contact: contact ?? this.contact,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      categories: categories ?? this.categories,
      priceRange: priceRange ?? this.priceRange,
      popularityScore: popularityScore ?? this.popularityScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

@JsonSerializable()
class PlaceLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  PlaceLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  Map<String, double> get coordinates => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory PlaceLocation.fromJson(Map<String, dynamic> json) => _$PlaceLocationFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceLocationToJson(this);
}

@JsonSerializable()
class Review {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, String> get user => {
        'id': userId,
        'name': userName,
      };

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

@JsonSerializable()
class OpeningHours {
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;
  final String? timezone;
  final Map<String, DayHours>? specialDays;

  OpeningHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    this.timezone,
    this.specialDays,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) => _$OpeningHoursFromJson(json);
  Map<String, dynamic> toJson() => _$OpeningHoursToJson(this);
}

@JsonSerializable()
class DayHours {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? note;

  DayHours({
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.note,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) => _$DayHoursFromJson(json);
  Map<String, dynamic> toJson() => _$DayHoursToJson(this);
}

@JsonSerializable()
class Contact {
  final String? phone;
  final String? email;
  final String? website;
  final Map<String, String>? socialMedia;

  Contact({
    this.phone,
    this.email,
    this.website,
    this.socialMedia,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);
}
