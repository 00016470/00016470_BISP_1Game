import 'package:equatable/equatable.dart';

class ClubMapInfo extends Equatable {
  final int id;
  final String name;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int pricePerHour;
  final int totalComputers;
  final int availableComputers;
  final int openingHour;
  final int closingHour;
  final String? imageUrl;

  const ClubMapInfo({
    required this.id,
    required this.name,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.pricePerHour,
    required this.totalComputers,
    required this.availableComputers,
    required this.openingHour,
    required this.closingHour,
    this.imageUrl,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get availabilityLabel {
    if (availableComputers == 0) return 'Full';
    if (availableComputers < totalComputers * 0.3) return 'Limited';
    return '$availableComputers free';
  }

  @override
  List<Object?> get props => [id, name, availableComputers];
}
