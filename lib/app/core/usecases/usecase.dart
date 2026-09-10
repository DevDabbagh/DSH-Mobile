import 'package:dartz/dartz.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';

/// Base class for all use cases.
/// [Type] is the return type, [Params] is the input parameter type.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when a use case requires no parameters.
class NoParams {
  const NoParams();
}
