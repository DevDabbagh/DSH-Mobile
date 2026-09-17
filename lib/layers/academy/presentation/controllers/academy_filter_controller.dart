import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

part 'academy_filter_controller.g.dart';

/// What the reader has narrowed the Academy listing down to.
///
/// The facets are the website's — `AcademyListing.tsx` filters on type and on
/// price — so the two surfaces answer the same question the same way:
///
///   const filtered = rest.filter((p) => {
///     const typeOk  = typeFilter === "all"  || p.type === typeFilter;
///     const priceOk = priceFilter === "all" ||
///       (priceFilter === "free" ? p.isFree : !p.isFree);
///     return typeOk && priceOk;
///   });
///
/// WHERE THIS DELIBERATELY GOES FURTHER THAN THE WEBSITE
///
/// The mobile frame (2266:1079) draws FOUR price chips — All prices, Free,
/// Paid, Scholarship — where the site has three. Scholarship is not a fourth
/// kind of price; it is a paid programme that holds places, which the site
/// already knows about (`ProgramMeta` prints "Scholarship available" when
/// `scholarshipNote` is set) but offers no way to filter by. So it is a real
/// facet here and the phone is the better surface for it.
///
/// That leaves Paid ambiguous, and the answer is the one the labels imply: a
/// scholarship programme is still paid, so it stays in Paid. Excluding it
/// would mean the three chips no longer add up to the whole library.
enum AcademyPrice {
  free,
  paid,
  scholarship;

  bool matches(AcademyProgram p) => switch (this) {
        AcademyPrice.free => p.isFree,
        AcademyPrice.paid => !p.isFree,
        // A note an editor left blank is not a scholarship.
        AcademyPrice.scholarship =>
          !p.isFree && p.scholarshipNote.trim().isNotEmpty,
      };
}

class AcademyFilter extends Equatable {
  /// Matched against title, description and who leads it — the three things
  /// printed on a card, so a reader can search for what they can see.
  final String query;

  final AcademyType? type;
  final AcademyPrice? price;

  const AcademyFilter({this.query = '', this.type, this.price});

  int get activeCount => (type != null ? 1 : 0) + (price != null ? 1 : 0);

  bool get isActive => activeCount > 0 || query.trim().isNotEmpty;

  AcademyFilter copyWith({
    String? query,
    AcademyType? type,
    bool clearType = false,
    AcademyPrice? price,
    bool clearPrice = false,
  }) =>
      AcademyFilter(
        query: query ?? this.query,
        type: clearType ? null : (type ?? this.type),
        price: clearPrice ? null : (price ?? this.price),
      );

  List<AcademyProgram> apply(List<AcademyProgram> all) {
    final q = query.trim().toLowerCase();

    return all.where((p) {
      if (type != null && p.type != type) return false;
      if (price != null && !price!.matches(p)) return false;
      if (q.isEmpty) return true;

      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.whoLeads.toLowerCase().contains(q);
    }).toList();
  }

  @override
  List<Object?> get props => [query, type, price];
}

/// Not keepAlive, like the Films and Studio filters: a filter is a question
/// being asked now, not content worth caching.
@riverpod
class AcademyFilterController extends _$AcademyFilterController {
  @override
  AcademyFilter build() => const AcademyFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setType(AcademyType? value) => state = value == null
      ? state.copyWith(clearType: true)
      : state.copyWith(type: value);

  void setPrice(AcademyPrice? value) => state = value == null
      ? state.copyWith(clearPrice: true)
      : state.copyWith(price: value);

  void clear() => state = const AcademyFilter();
}
