import '../../domain/entities/club.dart';

class ClubModel extends Club {
  const ClubModel({
    required super.id,
    required super.name,
    required super.location,
    required super.description,
    required super.pricePerHour,
    required super.rating,
    required super.totalReviews,
    super.imageUrl,
    required super.isActive,
    super.latitude,
    super.longitude,
    super.address,
    super.openingHour,
    super.closingHour,
    super.totalComputers,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      address: json['address'] as String?,
      openingHour: json['opening_hour'] as int?,
      closingHour: json['closing_hour'] as int?,
      totalComputers: json['total_computers'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'description': description,
        'price_per_hour': pricePerHour,
        'rating': rating,
        'total_reviews': totalReviews,
        'image_url': imageUrl,
        'is_active': isActive,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
}
