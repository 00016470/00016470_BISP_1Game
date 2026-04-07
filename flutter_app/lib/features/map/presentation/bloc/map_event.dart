import 'package:equatable/equatable.dart';

enum MapSortMode { none, topRated, cheapest }

abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapClubsLoadRequested extends MapEvent {
  final bool availableNow;
  final String? search;
  final MapSortMode sortMode;
  const MapClubsLoadRequested({
    this.availableNow = false,
    this.search,
    this.sortMode = MapSortMode.none,
  });
  @override
  List<Object?> get props => [availableNow, search, sortMode];
}

class MapSearchChanged extends MapEvent {
  final String query;
  const MapSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}
