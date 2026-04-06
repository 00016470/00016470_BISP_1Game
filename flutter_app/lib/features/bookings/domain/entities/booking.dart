import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final int id;
  final String clubName;
  final String clubLocation;
  final int clubId;
  final String date;
  final String startTime;
  final String endTime;
  final int computersCount;
  final double durationHours;
  final double totalPrice;
  final String status;
  final String createdAt;

  const Booking({
    required this.id,
    required this.clubName,
    required this.clubLocation,
    required this.clubId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.computersCount,
    required this.durationHours,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  /// Backend statuses: ACTIVE, COMPLETED, CANCELLED, EXPIRED
  bool get isUpcoming => status == 'ACTIVE';
  bool get isPast =>
      status == 'COMPLETED' || status == 'CANCELLED' || status == 'EXPIRED';

  @override
  List<Object> get props => [
        id, clubName, clubLocation, clubId, date, startTime, endTime,
        computersCount, durationHours, totalPrice, status, createdAt
      ];
}
