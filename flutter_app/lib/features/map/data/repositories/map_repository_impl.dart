import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/club_map_info.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource remoteDataSource;
  MapRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ClubMapInfo>>> getClubsForMap({
    bool availableNow = false,
    String? search,
  }) async {
    try {
      final clubs = await remoteDataSource.getClubsForMap(
        availableNow: availableNow,
        search: search,
      );
      return Right(clubs);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }
}
