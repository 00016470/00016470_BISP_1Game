import 'package:equatable/equatable.dart';

abstract class ClubDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClubDetailLoadRequested extends ClubDetailEvent {
  final int clubId;
  ClubDetailLoadRequested(this.clubId);

  @override
  List<Object> get props => [clubId];
}

class ClubDetailSlotsRequested extends ClubDetailEvent {
  final int clubId;
  final String date;

  ClubDetailSlotsRequested({required this.clubId, required this.date});

  @override
  List<Object> get props => [clubId, date];
}
