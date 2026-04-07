import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(const AdminInitial()) {
    on<AdminDashboardLoadRequested>(_onDashboard);
    on<AdminClubsLoadRequested>(_onClubs);
    on<AdminCreateClubRequested>(_onCreateClub);
    on<AdminUpdateClubRequested>(_onUpdateClub);
    on<AdminUsersLoadRequested>(_onUsers);
    on<AdminCreateUserRequested>(_onCreateUser);
    on<AdminApproveUserRequested>(_onApproveUser);
    on<AdminRejectUserRequested>(_onRejectUser);
    on<AdminDeleteUserRequested>(_onDeleteUser);
    on<AdminUserDetailLoadRequested>(_onUserDetail);
    on<AdminBookingsLoadRequested>(_onBookings);
    on<AdminPendingPaymentsLoadRequested>(_onPendingPayments);
    on<AdminPaymentValidateRequested>(_onValidate);
    on<AdminClubSessionsLoadRequested>(_onClubSessions);
    on<AdminClubRevenueLoadRequested>(_onClubRevenue);
    on<AdminMultiClubRevenueLoadRequested>(_onMultiClubRevenue);
  }

  Future<void> _onDashboard(
    AdminDashboardLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getDashboard();
    result.fold((f) => emit(AdminError(f.message)), (s) => emit(AdminDashboardLoaded(s)));
  }

  Future<void> _onClubs(
    AdminClubsLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getClubs();
    result.fold((f) => emit(AdminError(f.message)), (c) => emit(AdminClubsLoaded(c)));
  }

  Future<void> _onCreateClub(
    AdminCreateClubRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.createClub({
      'name': event.name,
      'location': event.location,
      'description': event.description,
      'price_per_hour': event.pricePerHour,
      'total_computers': event.totalComputers,
      'opening_hour': event.openingHour,
      'closing_hour': event.closingHour,
      if (event.address != null) 'address': event.address,
      if (event.latitude != null) 'latitude': event.latitude,
      if (event.longitude != null) 'longitude': event.longitude,
      if (event.imageUrl != null) 'image_url': event.imageUrl,
    });
    result.fold(
      (f) => emit(AdminError(f.message)),
      (club) => emit(AdminClubActionSuccess('Club created', club)),
    );
  }

  Future<void> _onUpdateClub(
    AdminUpdateClubRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.updateClub(event.clubId, event.fields);
    result.fold(
      (f) => emit(AdminError(f.message)),
      (club) => emit(AdminClubActionSuccess('Club updated', club)),
    );
  }

  Future<void> _onUsers(
    AdminUsersLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getUsers(pendingOnly: event.pendingOnly);
    result.fold((f) => emit(AdminError(f.message)), (u) => emit(AdminUsersLoaded(u)));
  }

  Future<void> _onCreateUser(
    AdminCreateUserRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.createUser({
      'username': event.username,
      'email': event.email,
      'password': event.password,
      'phone': event.phone,
    });
    result.fold((f) => emit(AdminError(f.message)), (u) => emit(AdminUserCreated(u)));
  }

  Future<void> _onApproveUser(
    AdminApproveUserRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.approveUser(event.userId);
    result.fold((f) => emit(AdminError(f.message)), (u) => emit(AdminUserApproved(u)));
  }

  Future<void> _onRejectUser(
    AdminRejectUserRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.rejectUser(event.userId);
    result.fold((f) => emit(AdminError(f.message)), (_) => emit(AdminUserRejected(event.userId)));
  }

  Future<void> _onDeleteUser(
    AdminDeleteUserRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.deleteUser(event.userId);
    result.fold((f) => emit(AdminError(f.message)), (_) => emit(AdminUserDeleted(event.userId)));
  }

  Future<void> _onUserDetail(
    AdminUserDetailLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getUserDetail(event.userId);
    result.fold((f) => emit(AdminError(f.message)), (d) => emit(AdminUserDetailLoaded(d)));
  }

  Future<void> _onBookings(
    AdminBookingsLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getBookings(clubId: event.clubId);
    result.fold((f) => emit(AdminError(f.message)), (b) => emit(AdminBookingsLoaded(b)));
  }

  Future<void> _onPendingPayments(
    AdminPendingPaymentsLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getPendingPayments();
    result.fold((f) => emit(AdminError(f.message)), (p) => emit(AdminPaymentsLoaded(p)));
  }

  Future<void> _onValidate(
    AdminPaymentValidateRequested event, Emitter<AdminState> emit,
  ) async {
    final result = await repository.validatePayment(event.paymentId);
    result.fold((f) => emit(AdminError(f.message)), (_) => emit(AdminPaymentValidated(event.paymentId)));
  }

  Future<void> _onClubSessions(
    AdminClubSessionsLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getClubSessions(event.clubId);
    result.fold((f) => emit(AdminError(f.message)), (s) => emit(AdminClubSessionsLoaded(s)));
  }

  Future<void> _onClubRevenue(
    AdminClubRevenueLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final result = await repository.getClubRevenue(event.clubId);
    result.fold((f) => emit(AdminError(f.message)), (r) => emit(AdminClubRevenueLoaded(r)));
  }

  Future<void> _onMultiClubRevenue(
    AdminMultiClubRevenueLoadRequested event, Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    final futures = event.clubIds.map((id) => repository.getClubRevenue(id));
    final results = await Future.wait(futures);

    final revenues = <ClubRevenue>[];
    for (final r in results) {
      final val = r.fold<ClubRevenue?>((_) => null, (rev) => rev);
      if (val == null) {
        emit(const AdminError('Failed to load revenue for some clubs'));
        return;
      }
      revenues.add(val);
    }

    // Merge revenue data
    final clubNames = revenues.map((r) => r.clubName).join(', ');
    final totalRevenue =
        revenues.fold<double>(0, (s, r) => s + r.totalRevenue);
    final totalSessions =
        revenues.fold<int>(0, (s, r) => s + r.totalSessions);
    final activeSessions =
        revenues.fold<int>(0, (s, r) => s + r.activeSessions);

    // Merge daily breakdown — sum by date
    final dayMap = <String, RevenueByDay>{};
    for (final rev in revenues) {
      for (final d in rev.revenueByDay) {
        final existing = dayMap[d.date];
        if (existing != null) {
          dayMap[d.date] = RevenueByDay(
            date: d.date,
            revenue: existing.revenue + d.revenue,
            bookingCount: existing.bookingCount + d.bookingCount,
          );
        } else {
          dayMap[d.date] = d;
        }
      }
    }
    final mergedDays = dayMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Merge recent sessions and sort by start time desc
    final allSessions = revenues.expand((r) => r.recentSessions).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final combined = ClubRevenue(
      clubId: 0,
      clubName: revenues.length == 1 ? clubNames : 'Selected Clubs',
      totalRevenue: totalRevenue,
      totalSessions: totalSessions,
      activeSessions: activeSessions,
      revenueByDay: mergedDays,
      recentSessions: allSessions.take(20).toList(),
    );

    emit(AdminMultiClubRevenueLoaded(combined, event.clubIds));
  }
}
