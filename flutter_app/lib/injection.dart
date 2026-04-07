import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/clubs/data/datasources/clubs_remote_datasource.dart';
import 'features/clubs/data/repositories/clubs_repository_impl.dart';
import 'features/clubs/domain/repositories/clubs_repository.dart';
import 'features/clubs/domain/usecases/get_clubs_usecase.dart';
import 'features/clubs/domain/usecases/get_club_detail_usecase.dart';
import 'features/clubs/domain/usecases/get_slots_usecase.dart';
import 'features/clubs/presentation/bloc/clubs_bloc.dart';
import 'features/clubs/presentation/bloc/club_detail_bloc.dart';
import 'features/bookings/data/datasources/bookings_remote_datasource.dart';
import 'features/bookings/data/repositories/bookings_repository_impl.dart';
import 'features/bookings/domain/repositories/bookings_repository.dart';
import 'features/bookings/domain/usecases/create_booking_usecase.dart';
import 'features/bookings/domain/usecases/get_bookings_usecase.dart';
import 'features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'features/bookings/presentation/bloc/bookings_bloc.dart';
// Phase 2
import 'features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/domain/repositories/wallet_repository.dart';
import 'features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'features/wallet/domain/usecases/top_up_wallet_usecase.dart';
import 'features/wallet/presentation/bloc/wallet_bloc.dart';
import 'features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/payment/data/datasources/payment_remote_datasource.dart';
import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/payment/domain/repositories/payment_repository.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/domain/repositories/admin_repository.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/map/data/datasources/map_remote_datasource.dart';
import 'features/map/data/repositories/map_repository_impl.dart';
import 'features/map/domain/repositories/map_repository.dart';
import 'features/map/presentation/bloc/map_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Core
  sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<Connectivity>()));
  sl.registerLazySingleton<ApiClient>(
      () => ApiClient(sl<FlutterSecureStorage>()));

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        secureStorage: sl<FlutterSecureStorage>(),
      ));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        authRepository: sl<AuthRepository>(),
      ));

  // ── Clubs ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ClubsRemoteDataSource>(
      () => ClubsRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ClubsRepository>(() => ClubsRepositoryImpl(
        remoteDataSource: sl<ClubsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));
  sl.registerLazySingleton(() => GetClubsUseCase(sl<ClubsRepository>()));
  sl.registerLazySingleton(
      () => GetClubDetailUseCase(sl<ClubsRepository>()));
  sl.registerLazySingleton(() => GetSlotsUseCase(sl<ClubsRepository>()));
  sl.registerFactory(
      () => ClubsBloc(getClubsUseCase: sl<GetClubsUseCase>()));
  sl.registerFactory(() => ClubDetailBloc(
        getClubDetailUseCase: sl<GetClubDetailUseCase>(),
        getSlotsUseCase: sl<GetSlotsUseCase>(),
      ));

  // ── Bookings ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<BookingsRemoteDataSource>(
      () => BookingsRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<BookingsRepository>(() => BookingsRepositoryImpl(
        remoteDataSource: sl<BookingsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));
  sl.registerLazySingleton(
      () => CreateBookingUseCase(sl<BookingsRepository>()));
  sl.registerLazySingleton(
      () => GetBookingsUseCase(sl<BookingsRepository>()));
  sl.registerLazySingleton(
      () => CancelBookingUseCase(sl<BookingsRepository>()));
  sl.registerFactory(() => BookingsBloc(
        createBookingUseCase: sl<CreateBookingUseCase>(),
        getBookingsUseCase: sl<GetBookingsUseCase>(),
        cancelBookingUseCase: sl<CancelBookingUseCase>(),
      ));

  // ── Wallet ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<WalletRepository>(() =>
      WalletRepositoryImpl(remoteDataSource: sl<WalletRemoteDataSource>()));
  sl.registerLazySingleton(() => GetWalletUseCase(sl<WalletRepository>()));
  sl.registerLazySingleton(
      () => TopUpWalletUseCase(sl<WalletRepository>()));
  sl.registerFactory(() => WalletBloc(
        getWalletUseCase: sl<GetWalletUseCase>(),
        topUpWalletUseCase: sl<TopUpWalletUseCase>(),
      ));

  // ── Transactions ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionRemoteDataSource>(
      () => TransactionRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<TransactionRepository>(() =>
      TransactionRepositoryImpl(
          remoteDataSource: sl<TransactionRemoteDataSource>()));
  sl.registerFactory(
      () => TransactionBloc(repository: sl<TransactionRepository>()));

  // ── Payments ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<PaymentRepository>(() =>
      PaymentRepositoryImpl(remoteDataSource: sl<PaymentRemoteDataSource>()));
  sl.registerFactory(
      () => PaymentBloc(repository: sl<PaymentRepository>()));

  // ── Admin ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<AdminRepository>(() =>
      AdminRepositoryImpl(remoteDataSource: sl<AdminRemoteDataSource>()));
  sl.registerFactory(
      () => AdminBloc(repository: sl<AdminRepository>()));

  // ── Map ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MapRemoteDataSource>(
      () => MapRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<MapRepository>(() =>
      MapRepositoryImpl(remoteDataSource: sl<MapRemoteDataSource>()));
  sl.registerFactory(
      () => MapBloc(repository: sl<MapRepository>()));
}
