import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final int id;
  final String clubName;
  final int clubSlot;
  final String date;
  final String startTime;
  final String endTime;
  final int computersCount;
  final int durationHours;
  final double totalPrice;
  final String status;
  final String createdAt;

  const Booking({
    required this.id,
    required this.clubName,
    required this.clubSlot,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.computersCount,
    required this.durationHours,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  bool get isUpcoming => status == 'confirmed' || status == 'pending';
  bool get isPast => status == 'completed' || status == 'cancelled';

  @override
  List<Object> get props => [
        id, clubName, clubSlot, date, startTime, endTime,
        computersCount, durationHours, totalPrice, status, createdAt
      ];
}
