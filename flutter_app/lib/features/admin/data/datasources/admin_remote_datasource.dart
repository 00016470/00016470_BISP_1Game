import '../../../../core/network/api_client.dart';
import '../../domain/entities/admin_stats.dart';

abstract class AdminRemoteDataSource {
  Future<AdminStats> getDashboard();
  Future<List<AdminClubItem>> getClubs();
  Future<AdminClubItem> createClub(Map<String, dynamic> data);
  Future<AdminClubItem> updateClub(int clubId, Map<String, dynamic> data);
  Future<List<AdminUserItem>> getUsers({bool pendingOnly = false});
  Future<AdminUserItem> createUser(Map<String, dynamic> data);
  Future<AdminUserItem> approveUser(int userId);
  Future<void> rejectUser(int userId);
  Future<void> deleteUser(int userId);
  Future<AdminUserDetail> getUserDetail(int userId);
  Future<List<AdminBookingItem>> getBookings({int? clubId});
  Future<List<AdminPaymentItem>> getPendingPayments();
  Future<AdminPaymentItem> validatePayment(int paymentId);
  Future<ClubSessions> getClubSessions(int clubId);
  Future<ClubRevenue> getClubRevenue(int clubId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;
  AdminRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AdminStats> getDashboard() async {
    final resp = await apiClient.dio.get('/admin/dashboard');
    final data = resp.data as Map<String, dynamic>;
    return AdminStats(
      totalRevenueToday: (data['total_revenue_today'] as num).toDouble(),
      activeBookings: data['active_bookings'] as int,
      pendingPayments: data['pending_payments'] as int,
      totalUsers: data['total_users'] as int,
      pendingUsers: data['pending_users'] as int? ?? 0,
      bookingsByClub: (data['bookings_by_club'] as List)
          .map((e) => BookingsByClub(
                clubId: e['club_id'] as int,
                clubName: e['club_name'] as String,
                bookingCount: e['booking_count'] as int,
                revenue: (e['revenue'] as num).toDouble(),
              ))
          .toList(),
      revenueByDay: (data['revenue_by_day'] as List)
          .map((e) => RevenueByDay(
                date: e['date'] as String,
                revenue: (e['revenue'] as num).toDouble(),
                bookingCount: e['booking_count'] as int,
              ))
          .toList(),
    );
  }

  @override
  Future<List<AdminClubItem>> getClubs() async {
    final resp = await apiClient.dio.get('/clubs');
    final list = resp.data as List;
    return list.map((e) => _parseClub(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AdminClubItem> createClub(Map<String, dynamic> data) async {
    final resp = await apiClient.dio.post('/clubs', data: data);
    return _parseClub(resp.data as Map<String, dynamic>);
  }

  @override
  Future<AdminClubItem> updateClub(int clubId, Map<String, dynamic> data) async {
    final resp = await apiClient.dio.put('/clubs/$clubId', data: data);
    return _parseClub(resp.data as Map<String, dynamic>);
  }

  AdminClubItem _parseClub(Map<String, dynamic> e) => AdminClubItem(
        id: e['id'] as int,
        name: e['name'] as String,
        location: e['location'] as String? ?? '',
        pricePerHour: (e['price_per_hour'] as num).toInt(),
        totalComputers: e['total_computers'] as int? ?? 0,
        rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
        isActive: e['is_active'] as bool? ?? true,
        openingHour: e['opening_hour'] as int? ?? 0,
        closingHour: e['closing_hour'] as int? ?? 24,
        address: e['address'] as String?,
        latitude: (e['latitude'] as num?)?.toDouble(),
        longitude: (e['longitude'] as num?)?.toDouble(),
        imageUrl: e['image_url'] as String?,
      );

  @override
  Future<List<AdminUserItem>> getUsers({bool pendingOnly = false}) async {
    final resp = await apiClient.dio.get('/admin/users',
        queryParameters: {'per_page': 100, 'pending_only': pendingOnly});
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => _parseUser(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminUserItem> createUser(Map<String, dynamic> data) async {
    final resp = await apiClient.dio.post('/admin/users', data: data);
    final e = resp.data as Map<String, dynamic>;
    return AdminUserItem(
      id: e['id'] as int,
      username: e['username'] as String,
      email: e['email'] as String,
      phone: '', isApproved: true,
      bookingCount: 0, totalSpent: 0, walletBalance: 0, joinedAt: '',
    );
  }

  @override
  Future<AdminUserItem> approveUser(int userId) async {
    final resp = await apiClient.dio.post('/admin/users/$userId/approve');
    return _parseUser(resp.data as Map<String, dynamic>);
  }

  @override
  Future<void> rejectUser(int userId) async {
    await apiClient.dio.post('/admin/users/$userId/reject');
  }

  @override
  Future<void> deleteUser(int userId) async {
    await apiClient.dio.delete('/admin/users/$userId');
  }

  @override
  Future<AdminUserDetail> getUserDetail(int userId) async {
    final resp = await apiClient.dio.get('/admin/users/$userId');
    final e = resp.data as Map<String, dynamic>;
    return AdminUserDetail(
      id: e['id'] as int,
      username: e['username'] as String,
      email: e['email'] as String,
      phone: e['phone'] as String?,
      isApproved: e['is_approved'] as bool? ?? true,
      joinedAt: e['joined_at'] as String? ?? '',
      walletBalance: (e['wallet_balance'] as num?)?.toDouble() ?? 0,
      currency: e['currency'] as String? ?? 'UZS',
      totalSpent: (e['total_spent'] as num?)?.toDouble() ?? 0,
      bookingCount: e['booking_count'] as int? ?? 0,
      bookings: (e['bookings'] as List? ?? []).cast<Map<String, dynamic>>(),
      payments: (e['payments'] as List? ?? []).cast<Map<String, dynamic>>(),
      transactions: (e['transactions'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
  }

  AdminUserItem _parseUser(Map<String, dynamic> e) => AdminUserItem(
        id: e['id'] as int,
        username: e['username'] as String,
        email: e['email'] as String,
        phone: e['phone'] as String? ?? '',
        isApproved: e['is_approved'] as bool? ?? true,
        bookingCount: e['booking_count'] as int? ?? 0,
        totalSpent: (e['total_spent'] as num?)?.toDouble() ?? 0,
        walletBalance: (e['wallet_balance'] as num?)?.toDouble() ?? 0,
        joinedAt: e['joined_at'] as String? ?? '',
      );

  @override
  Future<List<AdminBookingItem>> getBookings({int? clubId}) async {
    final qp = <String, dynamic>{'per_page': 50};
    if (clubId != null) qp['club_id'] = clubId;
    final resp = await apiClient.dio.get('/admin/bookings', queryParameters: qp);
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => _parseBooking(e as Map<String, dynamic>))
        .toList();
  }

  AdminBookingItem _parseBooking(Map<String, dynamic> e) {
    final startTime = DateTime.parse(e['start_time'] as String);
    final durationHours = (e['duration_hours'] as num).toDouble();
    return AdminBookingItem(
      id: e['id'] as int,
      userId: e['user_id'] as int,
      username: e['username'] as String? ?? '',
      clubId: e['club_id'] as int,
      clubName: e['club_name'] as String? ?? '',
      startTime: startTime,
      durationHours: durationHours,
      computersBooked: e['computers_booked'] as int? ?? 1,
      totalPrice: (e['total_price'] as num?)?.toDouble() ?? 0.0,
      status: e['status'] as String,
      paymentMethod: e['payment_method'] as String?,
      paymentStatus: e['payment_status'] as String?,
      createdAt: DateTime.parse(e['created_at'] as String),
    );
  }

  @override
  Future<List<AdminPaymentItem>> getPendingPayments() async {
    final resp = await apiClient.dio.get('/admin/payments', queryParameters: {'status': 'PENDING'});
    final data = resp.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => _parsePayment(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminPaymentItem> validatePayment(int paymentId) async {
    final resp = await apiClient.dio.post('/admin/payments/$paymentId/validate');
    return _parsePayment(resp.data as Map<String, dynamic>);
  }

  AdminPaymentItem _parsePayment(Map<String, dynamic> e) => AdminPaymentItem(
        id: e['id'] as int,
        userId: e['user_id'] as int,
        username: e['username'] as String? ?? '',
        bookingId: e['booking_id'] as int,
        clubName: e['club_name'] as String? ?? '',
        amount: (e['amount'] as num).toDouble(),
        method: e['method'] as String,
        status: e['status'] as String,
        createdAt: DateTime.parse(e['created_at'] as String),
      );

  @override
  Future<ClubSessions> getClubSessions(int clubId) async {
    final resp = await apiClient.dio.get('/admin/clubs/$clubId/sessions');
    final e = resp.data as Map<String, dynamic>;
    return ClubSessions(
      clubId: e['club_id'] as int,
      clubName: e['club_name'] as String,
      totalComputers: e['total_computers'] as int,
      activeSessions: _parseSessionList(e['active_sessions'] as List),
      upcomingSessions: _parseSessionList(e['upcoming_sessions'] as List),
      availableComputers: e['available_computers'] as int,
    );
  }

  @override
  Future<ClubRevenue> getClubRevenue(int clubId) async {
    final resp = await apiClient.dio.get('/admin/clubs/$clubId/revenue');
    final e = resp.data as Map<String, dynamic>;
    return ClubRevenue(
      clubId: e['club_id'] as int,
      clubName: e['club_name'] as String,
      totalRevenue: (e['total_revenue'] as num).toDouble(),
      totalSessions: e['total_sessions'] as int,
      activeSessions: e['active_sessions'] as int,
      revenueByDay: (e['revenue_by_day'] as List)
          .map((d) => RevenueByDay(
                date: d['date'] as String,
                revenue: (d['revenue'] as num).toDouble(),
                bookingCount: d['booking_count'] as int,
              ))
          .toList(),
      recentSessions: _parseSessionList(e['recent_sessions'] as List),
    );
  }

  List<ClubSessionItem> _parseSessionList(List data) => data.map((s) {
        final m = s as Map<String, dynamic>;
        return ClubSessionItem(
          bookingId: m['booking_id'] as int,
          userId: m['user_id'] as int,
          username: m['username'] as String,
          computersBooked: m['computers_booked'] as int,
          startTime: DateTime.parse(m['start_time'] as String),
          endTime: DateTime.parse(m['end_time'] as String),
          remainingMinutes: (m['remaining_minutes'] as num).toDouble(),
          totalPrice: (m['total_price'] as num?)?.toDouble(),
          status: m['status'] as String,
        );
      }).toList();
}
