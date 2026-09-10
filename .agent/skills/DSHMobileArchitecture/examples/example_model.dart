// lib/layers/films/data/models/film_model.dart
//
// freezed + json_annotation. Two things matter on the Supabase path:
//   1. Columns are snake_case  → @JsonKey(name: '...')
//   2. Text columns are JSONB  → { "en": …, "pt": …, "ar": … }
//      Resolve them with pickLang(), NEVER by reading ['en'] directly.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

part 'film_model.freezed.dart';
part 'film_model.g.dart';

@freezed
class FilmModel with _$FilmModel {
  const FilmModel._(); // required for custom getters and toEntity()

  const factory FilmModel({
    required String id,
    required String slug,

    /// JSONB: { "en": "...", "pt": "...", "ar": "..." }
    required Map<String, dynamic> title,
    @JsonKey(name: 'synopsis_short') Map<String, dynamic>? synopsisShort,

    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'poster_url') String? posterUrl,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @Default(<String>[]) List<String> themes,
  }) = _FilmModel;

  factory FilmModel.fromJson(Map<String, dynamic> json) =>
      _$FilmModelFromJson(json);

  /// Resolve multilingual fields against the active locale, then hand the
  /// domain layer plain strings. The locale is passed in rather than read
  /// from a global, so the mapping stays testable.
  Film toEntity(String locale, String defaultLocale) => Film(
        id: id,
        slug: slug,
        title: pickLang(title, locale, defaultLocale),
        synopsisShort: pickLang(synopsisShort, locale, defaultLocale),
        thumbnailUrl: thumbnailUrl ?? '',
        posterUrl: posterUrl ?? '',
        isFeatured: isFeatured,
        themes: themes,
      );
}
