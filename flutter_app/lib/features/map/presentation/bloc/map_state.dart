import 'package:equatable/equatable.dart';
import '../../domain/entities/club_map_info.dart';
import 'map_event.dart';

abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  final List<ClubMapInfo> clubs;
  final bool availableNow;
  final String searchQuery;
  final MapSortMode sortMode;
  const MapLoaded({
    required this.clubs,
    this.availableNow = false,
    this.searchQuery = '',
    this.sortMode = MapSortMode.none,
  });
  @override
  List<Object?> get props => [clubs, availableNow, searchQuery, sortMode];
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}
