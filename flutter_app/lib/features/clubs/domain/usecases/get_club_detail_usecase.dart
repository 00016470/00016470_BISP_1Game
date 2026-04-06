import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/clubs_repository.dart';

class GetClubDetailUseCase implements UseCase<Club, ClubDetailParams> {
  final ClubsRepository repository;
  GetClubDetailUseCase(this.repository);

  @override
  Future<Either<Failure, Club>> call(ClubDetailParams params) {
    return repository.getClubDetail(params.id);
  }
}

class ClubDetailParams extends Equatable {
  final int id;
  const ClubDetailParams({required this.id});

  @override
  List<Object> get props => [id];
}
