import 'package:equatable/equatable.dart';

class Club extends Equatable {
  final int id;
  final String name;
  final String location;
  final String description;
  final double pricePerHour;
  final double rating;
  final int totalReviews;
  final String? imageUrl;
  final bool isActive;

  const Club({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.pricePerHour,
    required this.rating,
    required this.totalReviews,
    this.imageUrl,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id, name, location, description, pricePerHour,
        rating, totalReviews, imageUrl, isActive
      ];
}
