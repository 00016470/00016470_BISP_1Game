import '../../../../core/network/api_client.dart';
import '../../domain/entities/club_map_info.dart';

abstract class MapRemoteDataSource {
  Future<List<ClubMapInfo>> getClubsForMap({
    bool availableNow = false,
    String? search,
  });
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final ApiClient apiClient;
  MapRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ClubMapInfo>> getClubsForMap({
    bool availableNow = false,
    String? search,
  }) async {
    final params = <String, dynamic>{
      if (availableNow) 'available_now': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await apiClient.dio.get(
      '/clubs/map',
      queryParameters: params,
    );
    final list = response.data as List;
    return list.map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  ClubMapInfo _parse(Map<String, dynamic> e) => ClubMapInfo(
        id: e['id'] as int,
        name: e['name'] as String,
        location: e['location'] as String,
        address: e['address'] as String?,
        latitude: e['latitude'] != null ? (e['latitude'] as num).toDouble() : null,
        longitude: e['longitude'] != null ? (e['longitude'] as num).toDouble() : null,
        rating: (e['rating'] as num).toDouble(),
        pricePerHour: e['price_per_hour'] as int,
        totalComputers: e['total_computers'] as int,
        availableComputers: e['available_computers'] as int? ?? 0,
        openingHour: e['opening_hour'] as int,
        closingHour: e['closing_hour'] as int,
        imageUrl: e['image_url'] as String?,
      );
}
