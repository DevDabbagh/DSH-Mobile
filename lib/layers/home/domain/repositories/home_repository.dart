import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/home/domain/entities/hero_slide.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';

abstract class HomeRepository {
  /// The header slider — the same cards the website shows, from the row
  /// Landing Settings writes. Empty when the slider is switched off there.
  Future<Either<Failure, List<HeroSlide>>> getHeroSlides();

  /// The Home screen's layout: enabled sections, in the dashboard's order.
  ///
  /// An empty list is a valid answer — it means the migration has not run
  /// yet, or an editor disabled everything — and the screen shows its empty
  /// state rather than an error.
  Future<Either<Failure, List<HomeSection>>> getSections();
}
