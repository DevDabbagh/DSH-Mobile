import 'package:equatable/equatable.dart';

/// Where a film is in its life. Drives the stage chip on the listing.
enum FilmStage {
  development,
  production,
  postProduction,
  festivals,
  distribution,
  impact;

  /// The database stores `post_production`; Dart names it `postProduction`.
  static FilmStage fromDb(String? value) {
    switch (value) {
      case 'production':
        return FilmStage.production;
      case 'post_production':
        return FilmStage.postProduction;
      case 'festivals':
        return FilmStage.festivals;
      case 'distribution':
        return FilmStage.distribution;
      case 'impact':
        return FilmStage.impact;
      default:
        return FilmStage.development;
    }
  }
}

enum FilmForm {
  documentary,
  fiction;

  static FilmForm fromDb(String? value) =>
      value == 'fiction' ? FilmForm.fiction : FilmForm.documentary;
}

enum FilmFormat {
  feature,
  short,
  series;

  static FilmFormat fromDb(String? value) {
    switch (value) {
      case 'short':
        return FilmFormat.short;
      case 'series':
        return FilmFormat.series;
      default:
        return FilmFormat.feature;
    }
  }
}

/// The credit block on a film's detail page.
///
/// These columns are plain text, not JSONB — names and years are the same in
/// every language, so they are not translated.
class FilmCredits extends Equatable {
  final String direction;
  final String production;
  final String coProduction;
  final String year;
  final String duration;
  final FilmForm form;
  final FilmFormat format;
  final String language;
  final String country;

  const FilmCredits({
    required this.direction,
    required this.production,
    required this.coProduction,
    required this.year,
    required this.duration,
    required this.form,
    required this.format,
    required this.language,
    required this.country,
  });

  @override
  List<Object?> get props => [
        direction,
        production,
        coProduction,
        year,
        duration,
        form,
        format,
        language,
        country,
      ];
}

class FilmFestival extends Equatable {
  final String name;
  final String year;
  final String? award;
  final String? selection;

  const FilmFestival({
    required this.name,
    required this.year,
    this.award,
    this.selection,
  });

  @override
  List<Object?> get props => [name, year, award, selection];
}

class FilmPressQuote extends Equatable {
  final String source;
  final String quote;

  const FilmPressQuote({required this.source, required this.quote});

  @override
  List<Object?> get props => [source, quote];
}

class FilmScreening extends Equatable {
  final String event;
  final String date;
  final String location;
  final String type;

  const FilmScreening({
    required this.event,
    required this.date,
    required this.location,
    required this.type,
  });

  @override
  List<Object?> get props => [event, date, location, type];
}

class Film extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String logline;
  final String synopsisShort;
  final String synopsisLong;
  final String editorialContext;
  final FilmCredits credits;
  final FilmStage stage;
  final List<String> themes;
  final String trailerUrl;
  final String thumbnailUrl;
  final String posterUrl;
  final List<String> detailsSliders;
  final List<FilmFestival> festivals;
  final List<FilmPressQuote> pressQuotes;
  final List<FilmScreening> screenings;
  final String accessMode;
  final bool isFeatured;

  const Film({
    required this.id,
    required this.title,
    required this.slug,
    required this.logline,
    required this.synopsisShort,
    required this.synopsisLong,
    required this.editorialContext,
    required this.credits,
    required this.stage,
    required this.themes,
    required this.trailerUrl,
    required this.thumbnailUrl,
    required this.posterUrl,
    required this.detailsSliders,
    required this.festivals,
    required this.pressQuotes,
    required this.screenings,
    required this.accessMode,
    required this.isFeatured,
  });

  /// The image the listing card should use, preferring the poster the way the
  /// website's cards do and falling back so a card is never a blank rectangle.
  String get cardImageUrl => posterUrl.isNotEmpty ? posterUrl : thumbnailUrl;

  @override
  List<Object?> get props => [id, slug];
}
