import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.userId,
    required super.bookingId,
    super.transactionId,
    required super.amount,
    required super.method,
    required super.status,
    super.validatedBy,
    super.validatedAt,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        bookingId: json['booking_id'] as int,
        transactionId: json['transaction_id'] as int?,
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        status: json['status'] as String,
        validatedBy: json['validated_by'] as int?,
        validatedAt: json['validated_at'] != null
            ? DateTime.parse(json['validated_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
