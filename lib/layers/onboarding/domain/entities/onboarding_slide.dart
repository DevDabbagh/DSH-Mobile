import 'package:equatable/equatable.dart';

/// One run of headline text, either plain or painted with the brand gradient.
///
/// A record rather than a class: it carries no behaviour, and using the same
/// shape in the domain and in the widget avoids a second type that exists
/// only to be converted into the first.
typedef TitleSegment = ({String text, bool highlight});

/// One first-launch onboarding slide, with its text already resolved to the
/// reader's language — the presentation layer never sees the JSONB shape.
class OnboardingSlide extends Equatable {
  final String id;
  final int sortOrder;

  /// One image is shown as it is; several drift past each other as a mosaic.
  /// There is no mode to choose — the count decides, so an editor uploads
  /// what they have and the slide does the right thing with it.
  final List<String> images;

  /// The headline as ordered runs. The Figma frames colour words in the
  /// middle of a sentence as well as at the end, so a single trailing
  /// highlight could not express them.
  final List<TitleSegment> titleSegments;

  final String description;
  final bool showLogo;

  const OnboardingSlide({
    required this.id,
    required this.sortOrder,
    required this.images,
    required this.titleSegments,
    required this.description,
    required this.showLogo,
  });

  /// The headline as one plain string, for anything that cannot show runs.
  String get plainTitle => titleSegments.map((s) => s.text).join();

  /// A slide with neither text nor images has nothing to show, and rendering
  /// it would look like a bug to the reader.
  bool get isEmpty => plainTitle.trim().isEmpty && images.isEmpty;

  @override
  List<Object?> get props => [
        id,
        sortOrder,
        images,
        titleSegments,
        description,
        showLogo,
      ];
}
