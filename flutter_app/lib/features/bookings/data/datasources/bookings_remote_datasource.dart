import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../config/constants.dart';
import '../models/booking_model.dart';

abstract class BookingsRemoteDataSource {
  Future<BookingModel> createBooking({
    required int clubSlot,
    required int computersCount,
    required int durationHours,
  });
  Future<List<BookingModel>> getBookings();
  Future<BookingModel> cancelBooking(int id);
}

class BookingsRemoteDataSourceImpl implements BookingsRemoteDataSource {
  final ApiClient apiClient;
  BookingsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<BookingModel> createBooking({
    required int clubSlot,
    required int computersCount,
    required int durationHours,
  }) async {
    final response = await apiClient.post(
      AppConstants.bookingsEndpoint,
      data: {
        'club_slot': clubSlot,
        'computers_count': computersCount,
        'duration_hours': durationHours,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw ServerException(
        message: 'Failed to create booking',
        statusCode: response.statusCode);
  }

  @override
  Future<List<BookingModel>> getBookings() async {
    final response = await apiClient.get(AppConstants.bookingsEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data.containsKey('results'))
              ? data['results'] as List
              : [];
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ServerException(
        message: 'Failed to fetch bookings',
        statusCode: response.statusCode);
  }

  @override
  Future<BookingModel> cancelBooking(int id) async {
    final response = await apiClient.post(
      '${AppConstants.bookingsEndpoint}$id${AppConstants.cancelEndpoint}',
    );
    if (response.statusCode == 200) {
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw ServerException(
        message: 'Failed to cancel booking',
        statusCode: response.statusCode);
  }
}
