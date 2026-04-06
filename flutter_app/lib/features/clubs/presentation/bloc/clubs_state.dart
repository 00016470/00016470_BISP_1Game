import 'package:equatable/equatable.dart';
import '../../domain/entities/club.dart';
import 'clubs_event.dart';

abstract class ClubsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClubsInitial extends ClubsState {}

class ClubsLoading extends ClubsState {}

class ClubsLoaded extends ClubsState {
  final List<Club> clubs;
  final List<Club> filteredClubs;
  final String searchQuery;
  final ClubSortType sortType;

  ClubsLoaded({
    required this.clubs,
    required this.filteredClubs,
    this.searchQuery = '',
    this.sortType = ClubSortType.none,
  });

  ClubsLoaded copyWith({
    List<Club>? clubs,
    List<Club>? filteredClubs,
    String? searchQuery,
    ClubSortType? sortType,
  }) {
    return ClubsLoaded(
      clubs: clubs ?? this.clubs,
      filteredClubs: filteredClubs ?? this.filteredClubs,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
    );
  }

  @override
  List<Object> get props => [clubs, filteredClubs, searchQuery, sortType];
}

class ClubsError extends ClubsState {
  final String message;
  ClubsError(this.message);

  @override
  List<Object> get props => [message];
}
