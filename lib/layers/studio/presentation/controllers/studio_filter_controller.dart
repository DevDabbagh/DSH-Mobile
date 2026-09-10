import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

part 'studio_filter_controller.g.dart';

/// What the reader has narrowed the studio library down to.
///
/// The twin of `FilmsFilter`, and the facets are again the website's:
/// `StudioListing.tsx` filters on `format` and `status`, so this does too.
///
/// Kept as its own class rather than a generic shared with films. They have
/// different facets of different types, and the generic version of this
/// ended up being a `Map<String, dynamic>` — which is to say, a shape that
/// compiles whatever you put in it.
class StudioFilter extends Equatable {
  /// Matched against title and the one-line description.
  final String query;

  final StudioFormat? format;
  final StudioStatus? status;

  const StudioFilter({
    this.query = '',
    this.format,
    this.status,
  });

  int get activeCount => (format != null ? 1 : 0) + (status != null ? 1 : 0);

  bool get isActive => activeCount > 0 || query.trim().isNotEmpty;

  StudioFilter copyWith({
    String? query,
    StudioFormat? format,
    bool clearFormat = false,
    StudioStatus? status,
    bool clearStatus = false,
  }) =>
      StudioFilter(
        query: query ?? this.query,
        format: clearFormat ? null : (format ?? this.format),
        status: clearStatus ? null : (status ?? this.status),
      );

  List<StudioProject> apply(List<StudioProject> all) {
    final q = query.trim().toLowerCase();

    return all.where((p) {
      if (format != null && p.format != format) return false;
      if (status != null && p.status != status) return false;
      if (q.isEmpty) return true;

      return p.title.toLowerCase().contains(q) ||
          p.oneLineDescription.toLowerCase().contains(q);
    }).toList();
  }

  @override
  List<Object?> get props => [query, format, status];
}

/// Not keepAlive, for the same reason [FilmsFilterController] is not: a
/// filter is a question being asked now, not content worth caching.
@riverpod
class StudioFilterController extends _$StudioFilterController {
  @override
  StudioFilter build() => const StudioFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setFormat(StudioFormat? value) => state = value == null
      ? state.copyWith(clearFormat: true)
      : state.copyWith(format: value);

  void setStatus(StudioStatus? value) => state = value == null
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: value);

  void clear() => state = const StudioFilter();
}
