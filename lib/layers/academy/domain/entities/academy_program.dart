import 'package:equatable/equatable.dart';

/// What kind of thing this is. Drives the chip on the card and the wording
/// of the join button — you enrol in a course, you download a toolkit.
enum AcademyType {
  course,
  workshop,
  toolkit,
  resource,
  mentorship;

  static AcademyType fromDb(String? value) {
    switch (value) {
      case 'workshop':
        return AcademyType.workshop;
      case 'toolkit':
        return AcademyType.toolkit;
      case 'resource':
        return AcademyType.resource;
      case 'mentorship':
        return AcademyType.mentorship;
      default:
        return AcademyType.course;
    }
  }
}

/// How it is delivered.
enum AcademyFormat {
  online,
  inPerson,
  hybrid,
  selfPaced,
  downloadable;

  /// The database writes snake_case; Dart names it camelCase.
  static AcademyFormat fromDb(String? value) {
    switch (value) {
      case 'in_person':
        return AcademyFormat.inPerson;
      case 'hybrid':
        return AcademyFormat.hybrid;
      case 'self_paced':
        return AcademyFormat.selfPaced;
      case 'downloadable':
        return AcademyFormat.downloadable;
      default:
        return AcademyFormat.online;
    }
  }
}

/// One line of the curriculum.
///
/// Predates migration 031 as a bare string in `objectives`; those rows are
/// read back as lessons with no duration and no lock, which is honest —
/// printing a running time nobody entered would be inventing data.
class AcademyLesson extends Equatable {
  final String title;
  final String duration;
  final bool locked;
  final String videoUrl;

  const AcademyLesson({
    required this.title,
    this.duration = '',
    this.locked = false,
    this.videoUrl = '',
  });

  bool get hasDuration => duration.trim().isNotEmpty;

  @override
  List<Object?> get props => [title, duration, locked, videoUrl];
}

class AcademyResource extends Equatable {
  final String id;
  final String title;

  /// pdf | link | toolkit
  final String type;
  final String url;

  /// "420 KB", as the editor typed it — DSH does not host these files, so
  /// there is no way to measure it.
  final String sizeLabel;
  final bool locked;

  const AcademyResource({
    required this.id,
    required this.title,
    required this.url,
    this.type = 'link',
    this.sizeLabel = '',
    this.locked = false,
  });

  @override
  List<Object?> get props => [id, title, type, url, sizeLabel, locked];
}

class AcademyTestimonial extends Equatable {
  final String quote;
  final String author;

  const AcademyTestimonial({required this.quote, required this.author});

  @override
  List<Object?> get props => [quote, author];
}

class AcademyPartnership extends Equatable {
  final String label;
  final String title;
  final String body;

  const AcademyPartnership({
    required this.label,
    required this.title,
    required this.body,
  });

  @override
  List<Object?> get props => [label, title, body];
}

/// The "Certification / Available after completion" pair in the meta row.
/// Both halves come from the editor; an empty one hides the row.
class AcademyCertification extends Equatable {
  final String label;
  final String value;

  const AcademyCertification({this.label = '', this.value = ''});

  bool get isEmpty => label.trim().isEmpty && value.trim().isEmpty;

  @override
  List<Object?> get props => [label, value];
}

/// A programme, course, workshop or toolkit.
///
/// Mirrors `AcademyProgram` in the website's `lib/types.ts` field for field,
/// so the two surfaces cannot drift into showing different things from the
/// same row.
class AcademyProgram extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String description;

  final AcademyType type;
  final AcademyFormat format;

  final String whoLeads;
  final String whoItsFor;
  final String scholarshipNote;
  final String howToJoin;

  final String duration;
  final String dates;

  /// Shown beside the type chip in the hero — "Mentorships · 2026".
  final String year;

  final bool isFree;
  final double? price;

  /// A price with no currency is not a price.
  final String currency;

  final String thumbnailUrl;

  final List<AcademyLesson> lessons;
  final List<AcademyResource> resources;
  final List<AcademyTestimonial> testimonials;
  final List<AcademyPartnership> partnerships;
  final AcademyCertification certification;

  final List<String> relatedFilmIds;
  final List<String> relatedStudioIds;

  final int enrolledCount;

  const AcademyProgram({
    required this.id,
    required this.slug,
    required this.title,
    this.description = '',
    this.type = AcademyType.course,
    this.format = AcademyFormat.online,
    this.whoLeads = '',
    this.whoItsFor = '',
    this.scholarshipNote = '',
    this.howToJoin = '',
    this.duration = '',
    this.dates = '',
    this.year = '',
    this.isFree = true,
    this.price,
    this.currency = 'EUR',
    this.thumbnailUrl = '',
    this.lessons = const [],
    this.resources = const [],
    this.testimonials = const [],
    this.partnerships = const [],
    this.certification = const AcademyCertification(),
    this.relatedFilmIds = const [],
    this.relatedStudioIds = const [],
    this.enrolledCount = 0,
  });

  /// A row an editor created but never filled in. The tab drops these rather
  /// than rendering a card with no title, which reads as a broken app.
  bool get isEmpty => title.trim().isEmpty;

  /// Free unless there is an actual number to charge. `is_free = false` with
  /// a null price is a half-finished row, and showing "Paid" with no amount
  /// is worse than showing nothing.
  bool get isPaid => !isFree && price != null && price! > 0;

  @override
  List<Object?> get props => [id, slug, title, type, format, isFree, price];
}
