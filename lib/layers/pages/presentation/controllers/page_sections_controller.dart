import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/pages/data/repositories/pages_repository_impl.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';

part 'page_sections_controller.g.dart';

/// The sections of one editable page, in order.
///
/// Parameterised by page name so About, and later Support or anything else the
/// Pages editor gains, all share this one controller rather than each growing
/// a near-identical copy.
///
/// The failure is thrown rather than swallowed: an empty page and a page that
/// failed to load look identical to a reader otherwise, and only one of them
/// deserves a retry button.
@riverpod
class PageSectionsList extends _$PageSectionsList {
  @override
  Future<List<PageSection>> build(String page) async {
    final result = await ref.watch(pagesRepositoryProvider).getSections(page);
    return result.fold((failure) => throw failure, (sections) => sections);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    final result = await ref.read(pagesRepositoryProvider).getSections(page);

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (sections) => AsyncValue.data(sections),
    );
  }
}
