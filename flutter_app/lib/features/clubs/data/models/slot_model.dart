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
    return SlotModel(
      id: json['id'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      totalComputers: json['total_computers'] as int,
      availableComputers: json['available_computers'] as int,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}
