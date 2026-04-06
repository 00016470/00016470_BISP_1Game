import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.clubName,
    required super.clubSlot,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.computersCount,
    required super.durationHours,
    required super.totalPrice,
    required super.status,
    required super.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      clubName: json['club_name'] as String? ?? '',
      clubSlot: json['club_slot'] as int,
      date: json['date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      computersCount: json['computers_count'] as int,
      durationHours: json['duration_hours'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'club_name': clubName,
        'club_slot': clubSlot,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'computers_count': computersCount,
        'duration_hours': durationHours,
        'total_price': totalPrice,
        'status': status,
        'created_at': createdAt,
      };
}
