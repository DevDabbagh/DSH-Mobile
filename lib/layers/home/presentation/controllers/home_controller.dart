import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/layers/home/data/repositories/home_repository_impl.dart';
import 'package:dsh_mobile/layers/home/domain/entities/hero_slide.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';

part 'home_controller.g.dart';

/// The Home screen's layout.
///
/// keepAlive: Home is the tab people leave and return to most, and it is the
/// most expensive screen to rebuild. Without it, every trip into a film and
/// back re-queried the layout and re-rendered every card from its shimmer,
/// which read as the app reloading itself.
@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  @override
  FutureOr<List<HomeSection>> build() async {
    final result = await ref.watch(homeRepositoryProvider).getSections();
    return result.fold((failure) => throw failure, (sections) => sections);
  }

  /// Pull-to-refresh. Re-reads rather than calling `build()` again, which
  /// would re-register this notifier's watches on every gesture.
  Future<void> refresh() async {
    state = const AsyncLoading();

    // The rails read content modules that the dashboard can hold on `mock`,
    // and that answer is cached for ten seconds. Clearing it here means a
    // pull-to-refresh after flipping a module actually shows the change,
    // instead of appearing to do nothing for ten seconds.
    ref.read(dataSourceServiceProvider).invalidateCache();

    final result = await ref.read(homeRepositoryProvider).getSections();

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (sections) => AsyncData(sections),
    );
  }
}

/// The header slider, shared with the website.
///
/// Its own provider rather than a field on the layout: the slider is one row
/// in a different table (`landing_page_config`), written by a different
/// editor, and a failure to read it must not take the whole Home screen down
/// with it — the carousel simply does not render.
@Riverpod(keepAlive: true)
Future<List<HeroSlide>> heroSlides(Ref ref) async {
  final result = await ref.watch(homeRepositoryProvider).getHeroSlides();
  return result.fold((_) => const [], (slides) => slides);
}
