import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/map_repository.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository repository;

  MapBloc({required this.repository}) : super(const MapInitial()) {
    on<MapClubsLoadRequested>(_onLoad);
    on<MapSearchChanged>(_onSearch);
  }

  Future<void> _onLoad(
    MapClubsLoadRequested event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());
    final result = await repository.getClubsForMap(
      availableNow: event.availableNow,
      search: event.search,
    );
    result.fold(
      (f) => emit(MapError(f.message)),
      (clubs) {
        final sorted = List.of(clubs);
        switch (event.sortMode) {
          case MapSortMode.topRated:
            sorted.sort((a, b) => b.rating.compareTo(a.rating));
          case MapSortMode.cheapest:
            sorted.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          case MapSortMode.none:
            break;
        }
        emit(MapLoaded(
          clubs: sorted,
          availableNow: event.availableNow,
          searchQuery: event.search ?? '',
          sortMode: event.sortMode,
        ));
      },
    );
  }

  Future<void> _onSearch(
    MapSearchChanged event,
    Emitter<MapState> emit,
  ) async {
    final loaded = state is MapLoaded ? state as MapLoaded : null;
    add(MapClubsLoadRequested(
      availableNow: loaded?.availableNow ?? false,
      search: event.query.isEmpty ? null : event.query,
      sortMode: loaded?.sortMode ?? MapSortMode.none,
    ));
  }
}
