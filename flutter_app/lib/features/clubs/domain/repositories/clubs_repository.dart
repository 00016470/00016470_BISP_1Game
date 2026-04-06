import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/club.dart';
import '../entities/slot.dart';

abstract class ClubsRepository {
  Future<Either<Failure, List<Club>>> getClubs();
  Future<Either<Failure, Club>> getClubDetail(int id);
  Future<Either<Failure, List<Slot>>> getSlots(
      {required int clubId, required String date});
}
