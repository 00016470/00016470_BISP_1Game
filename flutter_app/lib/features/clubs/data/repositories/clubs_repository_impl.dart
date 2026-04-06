import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/slot.dart';
import '../../domain/repositories/clubs_repository.dart';
import '../datasources/clubs_remote_datasource.dart';

class ClubsRepositoryImpl implements ClubsRepository {
  final ClubsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  List<Club>? _cachedClubs;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  ClubsRepositoryImpl(
      {required this.remoteDataSource, required this.networkInfo});

  bool get _isCacheValid =>
      _cachedClubs != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  @override
  Future<Either<Failure, List<Club>>> getClubs() async {
    if (_isCacheValid) return Right(_cachedClubs!);
    if (!await networkInfo.isConnected) {
      if (_cachedClubs != null) return Right(_cachedClubs!);
      return const Left(NetworkFailure());
    }
    try {
      final clubs = await remoteDataSource.getClubs();
      _cachedClubs = clubs;
      _cacheTime = DateTime.now();
      return Right(clubs);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Club>> getClubDetail(int id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final club = await remoteDataSource.getClubDetail(id);
      return Right(club);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Slot>>> getSlots(
      {required int clubId, required String date}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final slots =
          await remoteDataSource.getSlots(clubId: clubId, date: date);
      return Right(slots);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
