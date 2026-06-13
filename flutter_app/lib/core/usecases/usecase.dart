import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Abstract base class for all use cases in the application.
/// Use cases represent business logic operations that can succeed or fail.
/// They return Either<Failure, Type> to handle both success and error cases.
/// [Type] The type of the successful result.
/// [Params] The type of parameters required for the use case.
abstract class UseCase<Type, Params> {
  /// Executes the use case with the given parameters.
  /// Returns a Future containing Either a Failure or the successful result.
  Future<Either<Failure, Type>> call(Params params);
}

/// Parameter class for use cases that don't require any parameters.
/// Extends Equatable for proper comparison in tests.
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
