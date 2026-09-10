import 'package:equatable/equatable.dart';

/// One story on the Impact screen — a piece of work, told rather than counted.
///
/// The counterpart to [ImpactStat]: a figure says how much, a story says what
/// it looked like. Both are rows written on /admin/impact, and neither is
/// invented in the app any more.
///
/// Unlike `impact_stats.label`, `title` and `description` are JSONB, so these
/// arrive already resolved into the reader's language.
class ImpactStory extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  /// The film this story belongs to, if the editor linked one. Empty is the
  /// common case — most stories stand on their own.
  final String linkedFilm;

  const ImpactStory({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.linkedFilm = '',
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl, linkedFilm];
}
