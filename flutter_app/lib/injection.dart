
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
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<FlutterSecureStorage>()));

  // Auth datasources & repos
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        secureStorage: sl<FlutterSecureStorage>(),
      ));

  // Auth use cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));

  // Auth BLoC — singleton so the same auth state is shared across all routes
  sl.registerLazySingleton(() => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        authRepository: sl<AuthRepository>(),
      ));

  // Clubs datasources & repos
  sl.registerLazySingleton<ClubsRemoteDataSource>(
      () => ClubsRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<ClubsRepository>(() => ClubsRepositoryImpl(
        remoteDataSource: sl<ClubsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));

  // Clubs use cases
  sl.registerLazySingleton(() => GetClubsUseCase(sl<ClubsRepository>()));
  sl.registerLazySingleton(
      () => GetClubDetailUseCase(sl<ClubsRepository>()));
  sl.registerLazySingleton(() => GetSlotsUseCase(sl<ClubsRepository>()));

  // Clubs BLoC
  sl.registerFactory(
      () => ClubsBloc(getClubsUseCase: sl<GetClubsUseCase>()));
  sl.registerFactory(() => ClubDetailBloc(
        getClubDetailUseCase: sl<GetClubDetailUseCase>(),
        getSlotsUseCase: sl<GetSlotsUseCase>(),
      ));

  // Bookings datasources & repos
  sl.registerLazySingleton<BookingsRemoteDataSource>(
      () => BookingsRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<BookingsRepository>(() => BookingsRepositoryImpl(
        remoteDataSource: sl<BookingsRemoteDataSource>(),
        networkInfo: sl<NetworkInfo>(),
      ));

  // Bookings use cases
  sl.registerLazySingleton(
      () => CreateBookingUseCase(sl<BookingsRepository>()));
  sl.registerLazySingleton(
      () => GetBookingsUseCase(sl<BookingsRepository>()));
  sl.registerLazySingleton(
      () => CancelBookingUseCase(sl<BookingsRepository>()));

  // Bookings BLoC
  sl.registerFactory(() => BookingsBloc(
        createBookingUseCase: sl<CreateBookingUseCase>(),
        getBookingsUseCase: sl<GetBookingsUseCase>(),
        cancelBookingUseCase: sl<CancelBookingUseCase>(),
      ));
}
