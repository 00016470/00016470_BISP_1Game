
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaming_club_tashkent/core/error/failures.dart';
import 'package:gaming_club_tashkent/core/usecases/usecase.dart';
import 'package:gaming_club_tashkent/features/clubs/domain/entities/club.dart';
import 'package:gaming_club_tashkent/features/clubs/domain/usecases/get_clubs_usecase.dart';
import 'package:gaming_club_tashkent/features/clubs/presentation/bloc/clubs_bloc.dart';
import 'package:gaming_club_tashkent/features/clubs/presentation/bloc/clubs_event.dart';
import 'package:gaming_club_tashkent/features/clubs/presentation/bloc/clubs_state.dart';

class MockGetClubsUseCase extends Mock implements GetClubsUseCase {}

const _testClub = Club(
  id: 1,
  name: 'Test Club',
  location: 'Tashkent',
  description: 'Test',
  pricePerHour: 10000,
  rating: 4.5,
  totalReviews: 100,
  isActive: true,
);

void main() {
  late ClubsBloc bloc;
  late MockGetClubsUseCase mockGetClubs;

  setUp(() {
    mockGetClubs = MockGetClubsUseCase();
    bloc = ClubsBloc(getClubsUseCase: mockGetClubs);
    registerFallbackValue(NoParams());
  });

  tearDown(() => bloc.close());

  blocTest<ClubsBloc, ClubsState>(
    'emits ClubsLoaded on successful load',
    build: () {
      when(() => mockGetClubs(any()))
          .thenAnswer((_) async => const Right([_testClub]));
      return bloc;
    },
    act: (b) => b.add(ClubsLoadRequested()),
    expect: () => [isA<ClubsLoading>(), isA<ClubsLoaded>()],
    verify: (_) {
      verify(() => mockGetClubs(NoParams())).called(1);
    },
  );

  blocTest<ClubsBloc, ClubsState>(
    'emits ClubsError on failure',
    build: () {
      when(() => mockGetClubs(any())).thenAnswer(
          (_) async => const Left(NetworkFailure()));
      return bloc;
    },
    act: (b) => b.add(ClubsLoadRequested()),
    expect: () => [isA<ClubsLoading>(), isA<ClubsError>()],
  );

  blocTest<ClubsBloc, ClubsState>(
    'filters clubs on search',
    build: () {
      when(() => mockGetClubs(any()))
          .thenAnswer((_) async => const Right([_testClub]));
      return bloc;
    },
    act: (b) async {
      b.add(ClubsLoadRequested());
      await Future.delayed(const Duration(milliseconds: 100));
      b.add(ClubsSearchChanged('xyz'));
      await Future.delayed(const Duration(milliseconds: 600));
    },
    expect: () => [
      isA<ClubsLoading>(),
      isA<ClubsLoaded>(),
      isA<ClubsLoaded>(),
    ],
  );
}
