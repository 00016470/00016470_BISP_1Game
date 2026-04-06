import 'package:equatable/equatable.dart';

class Slot extends Equatable {
  final int id;
  final String startTime;
  final String endTime;
  final int totalComputers;
  final int availableComputers;
  final bool isAvailable;

  const Slot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.totalComputers,
    required this.availableComputers,
    required this.isAvailable,
  });

  double get availabilityRatio =>
      totalComputers > 0 ? availableComputers / totalComputers : 0;

  bool get isHighAvailability => availabilityRatio > 0.5;
  bool get isLowAvailability =>
      availabilityRatio > 0 && availabilityRatio <= 0.3;
  bool get isFull => availableComputers == 0;

  @override
  List<Object> get props => [
        id, startTime, endTime, totalComputers, availableComputers, isAvailable
      ];
}
