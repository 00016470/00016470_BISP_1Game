import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../config/constants.dart';
import '../models/club_model.dart';
import '../models/slot_model.dart';

abstract class ClubsRemoteDataSource {
  Future<List<ClubModel>> getClubs();
  Future<ClubModel> getClubDetail(int id);
  Future<List<SlotModel>> getSlots({required int clubId, required String date});
}

class ClubsRemoteDataSourceImpl implements ClubsRemoteDataSource {
  final ApiClient apiClient;
  ClubsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ClubModel>> getClubs() async {
    final response = await apiClient.get(AppConstants.clubsEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data.containsKey('results'))
              ? data['results'] as List
              : [];
      return list
          .map((e) => ClubModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(
        message: 'Failed to fetch clubs', statusCode: response.statusCode);
  }

  @override
  Future<ClubModel> getClubDetail(int id) async {
    final response =
        await apiClient.get('${AppConstants.clubsEndpoint}$id/');
    if (response.statusCode == 200) {
      return ClubModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw ServerException(
        message: 'Club not found', statusCode: response.statusCode);
  }

  @override
  Future<List<SlotModel>> getSlots(
      {required int clubId, required String date}) async {
    final response = await apiClient.get(
      '${AppConstants.clubsEndpoint}$clubId${AppConstants.slotsEndpoint}',
      queryParameters: {'date': date},
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data.containsKey('results'))
              ? data['results'] as List
              : [];
      return list
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(
        message: 'Failed to fetch slots', statusCode: response.statusCode);
  }
}
