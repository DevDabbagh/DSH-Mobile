import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/home/data/datasources/home_remote_datasource.dart';
import 'package:dsh_mobile/layers/home/data/models/hero_slide_model.dart';
import 'package:dsh_mobile/layers/home/data/models/home_section_model.dart';
import 'package:dsh_mobile/layers/home/domain/entities/hero_slide.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';
import 'package:dsh_mobile/layers/home/domain/repositories/home_repository.dart';

part 'home_repository_impl.g.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _dataSource;
  final String _locale;

  HomeRepositoryImpl(this._dataSource, this._locale);

  @override
  Future<Either<Failure, List<HomeSection>>> getSections() async {
    try {
      final rows = await _dataSource.getSections();

      final sections = rows
          .map((r) => HomeSectionModel.fromRow(
                r,
                _locale,
                SupabaseConfig.defaultLocale,
              ))
          .whereType<HomeSection>()
          .toList();

      return Right(sections);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<HeroSlide>>> getHeroSlides() async {
    try {
      final row = await _dataSource.getHeroSlider();
      return Right(HeroSlideModel.fromConfigRow(row));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
HomeRepository homeRepository(Ref ref) {
  // watch: changing language rebuilds this provider so the headings refetch
  // in the new language along with the interface.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return HomeRepositoryImpl(
    ref.read(homeRemoteDataSourceProvider),
    locale,
  );
}
