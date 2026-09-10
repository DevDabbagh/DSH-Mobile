import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:dsh_mobile/layers/onboarding/data/models/onboarding_slide_model.dart';
import 'package:dsh_mobile/layers/onboarding/domain/entities/onboarding_slide.dart';
import 'package:dsh_mobile/layers/onboarding/domain/repositories/onboarding_repository.dart';

part 'onboarding_repository_impl.g.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource _dataSource;
  final String _locale;

  OnboardingRepositoryImpl(this._dataSource, this._locale);

  @override
  Future<Either<Failure, List<OnboardingSlide>>> getSlides() async {
    try {
      final rows = await _dataSource.getSlides();

      final slides = rows
          .map((r) => OnboardingSlideModel.fromRow(
                r,
                _locale,
                SupabaseConfig.defaultLocale,
              ))
          // A row an editor created but never filled in would render as a
          // blank screen, which reads as a broken app rather than an empty one.
          .where((s) => !s.isEmpty)
          .toList();

      return Right(slides);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  // watch, not read: switching language rebuilds this provider, which
  // invalidates the controller above it and refetches the slides in the new
  // language. With `read` the interface would switch and the content
  // wouldn't — half-translated, and confusing to debug.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return OnboardingRepositoryImpl(
    ref.read(onboardingRemoteDataSourceProvider),
    locale,
  );
}
