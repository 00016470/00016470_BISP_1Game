import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/slot.dart';
import '../repositories/clubs_repository.dart';

class GetSlotsUseCase implements UseCase<List<Slot>, SlotsParams> {
  final ClubsRepository repository;
  GetSlotsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Slot>>> call(SlotsParams params) {
    return repository.getSlots(clubId: params.clubId, date: params.date);
  }
}

class SlotsParams extends Equatable {
  final int clubId;
  final String date;
  const SlotsParams({required this.clubId, required this.date});

  @override
  List<Object> get props => [clubId, date];
}
