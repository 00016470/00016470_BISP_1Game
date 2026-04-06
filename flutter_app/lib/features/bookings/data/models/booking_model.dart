import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.clubName,
    required super.clubLocation,
    required super.clubId,
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
    String startTime = '';
    String endTime = '';
    String date = json['date'] as String? ?? '';

    final startRaw = json['start_time'];
    final endRaw = json['end_time'];

    if (startRaw is String) {
      final parts = startRaw.split('T');
      if (parts.length >= 2) {
        final t = parts[1];
        startTime = t.length >= 5 ? t.substring(0, 5) : t;
      }
      if (date.isEmpty) {
        try {
          final dt = DateTime.parse(startRaw).toUtc();
          date =
              '${_months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
        } catch (_) {
          date = parts[0];
        }
      }
    }

    if (endRaw is String) {
      final parts = endRaw.split('T');
      if (parts.length >= 2) {
        final t = parts[1];
        endTime = t.length >= 5 ? t.substring(0, 5) : t;
      }
    }

    return BookingModel(
      id: json['id'] as int,
      clubName: json['club_name'] as String? ?? '',
      clubLocation: json['club_location'] as String? ?? '',
      clubId: json['club_id'] as int? ?? 0,
      date: date,
      startTime: startTime,
      endTime: endTime,
      computersCount: (json['computers_count'] as int?) ??
          (json['computers_booked'] as int? ?? 0),
      durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'club_name': clubName,
        'club_location': clubLocation,
        'club_id': clubId,
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
