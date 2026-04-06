import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/clubs_repository.dart';

class GetClubsUseCase implements UseCase<List<Club>, NoParams> {
  final ClubsRepository repository;
  GetClubsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Club>>> call(NoParams params) {
    return repository.getClubs();
  }
}
