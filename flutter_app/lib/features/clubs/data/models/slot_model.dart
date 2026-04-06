import '../../domain/entities/slot.dart';

class SlotModel extends Slot {
  const SlotModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.totalComputers,
    required super.availableComputers,
    required super.isAvailable,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    // Support both old format {time, available_computers} and new full format
    final startTime =
        json['start_time'] as String? ?? json['time'] as String? ?? '00:00';
    final endTime =
        json['end_time'] as String? ?? _addOneHour(startTime);
    final availableComputers = json['available_computers'] as int? ?? 0;
    return SlotModel(
      id: json['id'] as int? ?? 0,
      startTime: startTime,
      endTime: endTime,
      totalComputers: json['total_computers'] as int? ?? availableComputers,
      availableComputers: availableComputers,
      isAvailable: json['is_available'] as bool? ?? availableComputers > 0,
    );
  }

  static String _addOneHour(String time) {
    if (time.length < 5) return time;
    final parts = time.split(':');
    final hour = (int.tryParse(parts[0]) ?? 0) + 1;
    return '${hour.toString().padLeft(2, '0')}:${parts.length > 1 ? parts[1] : '00'}';
  }
}
