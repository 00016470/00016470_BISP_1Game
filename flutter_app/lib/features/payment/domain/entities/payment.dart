import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final int id;
  final int userId;
  final int bookingId;
  final int? transactionId;
  final double amount;
  final String method;
  final String status;
  final int? validatedBy;
  final DateTime? validatedAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.bookingId,
    this.transactionId,
    required this.amount,
    required this.method,
    required this.status,
    this.validatedBy,
    this.validatedAt,
    required this.createdAt,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';

  @override
  List<Object?> get props => [id, bookingId, amount, method, status];
}
