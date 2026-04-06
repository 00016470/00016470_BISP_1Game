import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:gaming_club_tashkent/core/error/failures.dart';
import 'package:gaming_club_tashkent/core/usecases/usecase.dart';
import 'package:gaming_club_tashkent/features/clubs/domain/entities/club.dart';
import 'package:gaming_club_tashkent/features/clubs/domain/repositories/clubs_repository.dart';
import 'package:gaming_club_tashkent/features/clubs/domain/usecases/get_clubs_usecase.dart';

class MockClubsRepository extends Mock implements ClubsRepository {}

void main() {
  late GetClubsUseCase useCase;
  late MockClubsRepository mockRepository;

  setUp(() {
    mockRepository = MockClubsRepository();
    useCase = GetClubsUseCase(mockRepository);
  });

  final tClubs = [
    const Club(
      id: 1,
      name: 'Test Club',
      location: 'Tashkent',
      description: 'Test description',
      pricePerHour: 15.0,
      rating: 4.5,
      totalReviews: 100,
      isActive: true,
    ),
  ];

  test('should return list of clubs from repository', () async {
    when(() => mockRepository.getClubs())
        .thenAnswer((_) async => Right(tClubs));

    final result = await useCase(NoParams());

    expect(result, Right(tClubs));
    verify(() => mockRepository.getClubs()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when repository fails', () async {
    when(() => mockRepository.getClubs()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server error')));

    final result = await useCase(NoParams());

    expect(result, const Left(ServerFailure(message: 'Server error')));
  });

  test('should return NetworkFailure when offline', () async {
    when(() => mockRepository.getClubs())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(NoParams());

    expect(result, const Left(NetworkFailure()));
  });
}
