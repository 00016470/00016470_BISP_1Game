import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/usecases/get_club_detail_usecase.dart';
import '../../domain/usecases/get_slots_usecase.dart';
import 'club_detail_event.dart';
import 'club_detail_state.dart';

class ClubDetailBloc extends Bloc<ClubDetailEvent, ClubDetailState> {
  final GetClubDetailUseCase getClubDetailUseCase;
  final GetSlotsUseCase getSlotsUseCase;

  ClubDetailBloc({
    required this.getClubDetailUseCase,
    required this.getSlotsUseCase,
  }) : super(ClubDetailInitial()) {
    on<ClubDetailLoadRequested>(_onLoadRequested);
    on<ClubDetailSlotsRequested>(_onSlotsRequested);
  }

  Future<void> _onLoadRequested(
    ClubDetailLoadRequested event,
    Emitter<ClubDetailState> emit,
  ) async {
    emit(ClubDetailLoading());
    final clubResult =
        await getClubDetailUseCase(ClubDetailParams(id: event.clubId));
    await clubResult.fold(
      (failure) async => emit(ClubDetailError(failure.message)),
      (club) async {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        emit(ClubDetailLoaded(
          club: club,
          slots: [],
          slotsLoading: true,
          selectedDate: today,
        ));
        final slotsResult = await getSlotsUseCase(
            SlotsParams(clubId: event.clubId, date: today));
        slotsResult.fold(
          (failure) {
            if (state is ClubDetailLoaded) {
              emit((state as ClubDetailLoaded)
                  .copyWith(slotsLoading: false));
            }
          },
          (slots) {
            if (state is ClubDetailLoaded) {
              emit((state as ClubDetailLoaded)
                  .copyWith(slots: slots, slotsLoading: false));
            }
          },
        );
      },
    );
  }

  Future<void> _onSlotsRequested(
    ClubDetailSlotsRequested event,
    Emitter<ClubDetailState> emit,
  ) async {
    if (state is ClubDetailLoaded) {
      final current = state as ClubDetailLoaded;
      emit(current.copyWith(slotsLoading: true, selectedDate: event.date));
      final result = await getSlotsUseCase(
          SlotsParams(clubId: event.clubId, date: event.date));
      result.fold(
        (failure) => emit(current.copyWith(slotsLoading: false)),
        (slots) =>
            emit(current.copyWith(slots: slots, slotsLoading: false)),
      );
    }
  }
}
