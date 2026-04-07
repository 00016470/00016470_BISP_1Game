import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final int id;
  final int userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedBalance =>
      '${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} $currency';

  @override
  List<Object?> get props => [id, userId, balance, currency];
}
