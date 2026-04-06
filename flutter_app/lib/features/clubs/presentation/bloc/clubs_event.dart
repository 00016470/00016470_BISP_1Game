import 'package:equatable/equatable.dart';

abstract class ClubsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClubsLoadRequested extends ClubsEvent {}

class ClubsSearchChanged extends ClubsEvent {
  final String query;
  ClubsSearchChanged(this.query);

  @override
  List<Object> get props => [query];
}

class ClubsSortChanged extends ClubsEvent {
  final ClubSortType sortType;
  ClubsSortChanged(this.sortType);

  @override
  List<Object> get props => [sortType];
}

enum ClubSortType { none, byRating, byPrice }
