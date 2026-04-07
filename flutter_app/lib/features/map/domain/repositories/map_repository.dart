import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/club_map_info.dart';

abstract class MapRepository {
  Future<Either<Failure, List<ClubMapInfo>>> getClubsForMap({
    bool availableNow = false,
    String? search,
  });
}
