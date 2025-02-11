// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      location:
          PlaceLocation.fromJson(json['location'] as Map<String, dynamic>),
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      rating: (json['rating'] as num).toDouble(),
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      openingHours:
          OpeningHours.fromJson(json['openingHours'] as Map<String, dynamic>),
      contact: Contact.fromJson(json['contact'] as Map<String, dynamic>),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      priceRange: (json['priceRange'] as num).toInt(),
      popularityScore: (json['popularityScore'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PlaceToJson(Place instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'location': instance.location,
      'images': instance.images,
      'rating': instance.rating,
      'reviews': instance.reviews,
      'openingHours': instance.openingHours,
      'contact': instance.contact,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'categories': instance.categories,
      'priceRange': instance.priceRange,
      'popularityScore': instance.popularityScore,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

PlaceLocation _$PlaceLocationFromJson(Map<String, dynamic> json) =>
    PlaceLocation(
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
    );

Map<String, dynamic> _$PlaceLocationToJson(PlaceLocation instance) =>
    <String, dynamic>{
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'postalCode': instance.postalCode,
    };

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
    };

OpeningHours _$OpeningHoursFromJson(Map<String, dynamic> json) => OpeningHours(
      monday: DayHours.fromJson(json['monday'] as Map<String, dynamic>),
      tuesday: DayHours.fromJson(json['tuesday'] as Map<String, dynamic>),
      wednesday: DayHours.fromJson(json['wednesday'] as Map<String, dynamic>),
      thursday: DayHours.fromJson(json['thursday'] as Map<String, dynamic>),
      friday: DayHours.fromJson(json['friday'] as Map<String, dynamic>),
      saturday: DayHours.fromJson(json['saturday'] as Map<String, dynamic>),
      sunday: DayHours.fromJson(json['sunday'] as Map<String, dynamic>),
      timezone: json['timezone'] as String?,
      specialDays: (json['specialDays'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, DayHours.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$OpeningHoursToJson(OpeningHours instance) =>
    <String, dynamic>{
      'monday': instance.monday,
      'tuesday': instance.tuesday,
      'wednesday': instance.wednesday,
      'thursday': instance.thursday,
      'friday': instance.friday,
      'saturday': instance.saturday,
      'sunday': instance.sunday,
      'timezone': instance.timezone,
      'specialDays': instance.specialDays,
    };

DayHours _$DayHoursFromJson(Map<String, dynamic> json) => DayHours(
      isOpen: json['isOpen'] as bool,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$DayHoursToJson(DayHours instance) => <String, dynamic>{
      'isOpen': instance.isOpen,
      'openTime': instance.openTime,
      'closeTime': instance.closeTime,
      'note': instance.note,
    };

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      socialMedia: (json['socialMedia'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'socialMedia': instance.socialMedia,
    };
