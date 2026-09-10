import 'package:equatable/equatable.dart';

enum StudioFormat {
  docuseries,
  videocast,
  podcast,
  series,
  other;

  static StudioFormat fromDb(String? value) {
    switch (value) {
      case 'docuseries':
        return StudioFormat.docuseries;
      case 'videocast':
        return StudioFormat.videocast;
      case 'podcast':
        return StudioFormat.podcast;
      case 'series':
        return StudioFormat.series;
      default:
        return StudioFormat.other;
    }
  }
}

enum StudioStatus {
  ongoing,
  complete,
  upcoming;

  static StudioStatus fromDb(String? value) {
    switch (value) {
      case 'ongoing':
        return StudioStatus.ongoing;
      case 'complete':
        return StudioStatus.complete;
      default:
        return StudioStatus.upcoming;
    }
  }
}

/// A glossary term or a recommendation card on an episode page. Both sections
/// share this shape in the database, so they share it here.
class StudioEntry extends Equatable {
  final String term;
  final String definition;
  final String? source;
  final String? imageUrl;

  const StudioEntry({
    required this.term,
    required this.definition,
    this.source,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [term, definition, source, imageUrl];
}

class StudioEpisode extends Equatable {
  final String title;
  final String description;
  final String? duration;
  final String? subtitle;
  final int? number;
  final int? season;
  final String? year;
  final String? guest;
  final String? imageUrl;
  final String? slug;
  final String status;
  final String? videoUrl;
  final String? videoProvider;

  /// The editorial half of the episode page. Each is null — not empty — when
  /// there is nothing to show, so the section hides its heading too.
  final List<String>? quotes;
  final List<StudioEntry>? glossary;
  final String? glossaryIntro;
  final String? glossaryNote;
  final List<StudioEntry>? recommendations;
  final String? recommendationsIntro;
  final String? recommendationsNote;
  final List<String>? gallery;
  final String? galleryIntro;

  const StudioEpisode({
    required this.title,
    required this.description,
    required this.status,
    this.duration,
    this.subtitle,
    this.number,
    this.season,
    this.year,
    this.guest,
    this.imageUrl,
    this.slug,
    this.videoUrl,
    this.videoProvider,
    this.quotes,
    this.glossary,
    this.glossaryIntro,
    this.glossaryNote,
    this.recommendations,
    this.recommendationsIntro,
    this.recommendationsNote,
    this.gallery,
    this.galleryIntro,
  });

  bool get hasVideo => (videoUrl ?? '').isNotEmpty;

  @override
  List<Object?> get props => [slug, season, number, title];
}

/// Credits differ from a film's: hosts and partners are comma-separated lists
/// in one column, and several fields are optional.
class StudioCredits extends Equatable {
  final String production;
  final String coProduction;
  final List<String> hosts;
  final List<String> partners;
  final String year;
  final String language;
  final String? direction;
  final String? duration;
  final String? form;
  final String? formatLabel;
  final String? country;

  const StudioCredits({
    required this.production,
    required this.coProduction,
    required this.hosts,
    required this.partners,
    required this.year,
    required this.language,
    this.direction,
    this.duration,
    this.form,
    this.formatLabel,
    this.country,
  });

  @override
  List<Object?> get props => [
        production,
        coProduction,
        hosts,
        partners,
        year,
        language,
        direction,
        duration,
        form,
        formatLabel,
        country,
      ];
}

class StudioListenLink extends Equatable {
  final String platform;
  final String url;

  const StudioListenLink({required this.platform, required this.url});

  @override
  List<Object?> get props => [platform, url];
}

class StudioProject extends Equatable {
  final String id;
  final String title;
  final String slug;
  final StudioFormat format;
  final String oneLineDescription;
  final String synopsisShort;
  final String synopsisLong;
  final List<StudioEpisode> episodes;
  final StudioCredits credits;
  final List<String>? stills;
  final StudioStatus status;
  final String editorialContext;
  final List<StudioListenLink> listenLinks;
  final List<String> relatedFilmIds;
  final List<String> relatedArticleIds;
  final String thumbnailUrl;
  final String coverUrl;

  const StudioProject({
    required this.id,
    required this.title,
    required this.slug,
    required this.format,
    required this.oneLineDescription,
    required this.synopsisShort,
    required this.synopsisLong,
    required this.episodes,
    required this.credits,
    required this.status,
    required this.editorialContext,
    required this.listenLinks,
    required this.relatedFilmIds,
    required this.relatedArticleIds,
    required this.thumbnailUrl,
    required this.coverUrl,
    this.stills,
  });

  String get cardImageUrl => thumbnailUrl.isNotEmpty ? thumbnailUrl : coverUrl;

  /// Find an episode within this project. Episode pages are reached through
  /// their project, so this saves a second query.
  StudioEpisode? episodeBySlug(String episodeSlug) {
    for (final e in episodes) {
      if (e.slug == episodeSlug) return e;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, slug];
}
