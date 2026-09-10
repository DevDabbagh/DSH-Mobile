import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/onboarding/domain/entities/onboarding_slide.dart';

abstract class OnboardingRepository {
  /// Enabled slides in display order.
  ///
  /// An empty list is a valid answer, not an error: with no slides configured
  /// the app skips onboarding and opens on Home.
  Future<Either<Failure, List<OnboardingSlide>>> getSlides();
}
