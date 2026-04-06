import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/club.dart';
import '../../domain/usecases/get_clubs_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import 'clubs_event.dart';
import 'clubs_state.dart';

class ClubsBloc extends Bloc<ClubsEvent, ClubsState> {
  final GetClubsUseCase getClubsUseCase;
  Timer? _searchDebounce;
  String _pendingQuery = '';

  ClubsBloc({required this.getClubsUseCase}) : super(ClubsInitial()) {
    on<ClubsLoadRequested>(_onLoadRequested);
    on<ClubsSearchChanged>(_onSearchChanged);
    on<ClubsSortChanged>(_onSortChanged);
    on<_ClubsApplySearch>(_onApplySearch);
  }

  Future<void> _onLoadRequested(
      ClubsLoadRequested event, Emitter<ClubsState> emit) async {
    emit(ClubsLoading());
    final result = await getClubsUseCase(NoParams());
    result.fold(
      (failure) => emit(ClubsError(failure.message)),
      (clubs) => emit(ClubsLoaded(clubs: clubs, filteredClubs: clubs)),
    );
  }

  void _onSearchChanged(ClubsSearchChanged event, Emitter<ClubsState> emit) {
    _pendingQuery = event.query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      add(_ClubsApplySearch(_pendingQuery));
    });
  }

  void _onApplySearch(_ClubsApplySearch event, Emitter<ClubsState> emit) {
    if (state is ClubsLoaded) {
      final current = state as ClubsLoaded;
      final filtered =
          _filterAndSort(current.clubs, event.query, current.sortType);
      emit(current.copyWith(filteredClubs: filtered, searchQuery: event.query));
    }
  }

  void _onSortChanged(ClubsSortChanged event, Emitter<ClubsState> emit) {
    if (state is ClubsLoaded) {
      final current = state as ClubsLoaded;
      final filtered =
          _filterAndSort(current.clubs, current.searchQuery, event.sortType);
      emit(current.copyWith(filteredClubs: filtered, sortType: event.sortType));
    }
  }

  List<Club> _filterAndSort(
      List<Club> clubs, String query, ClubSortType sortType) {
    var filtered = query.isEmpty
        ? List<Club>.from(clubs)
        : clubs.where((c) {
            final q = query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.location.toLowerCase().contains(q);
          }).toList();

    switch (sortType) {
      case ClubSortType.byRating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ClubSortType.byPrice:
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case ClubSortType.none:
        break;
    }
    return filtered;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

class _ClubsApplySearch extends ClubsEvent {
  final String query;
  _ClubsApplySearch(this.query);

  @override
  List<Object> get props => [query];
}
