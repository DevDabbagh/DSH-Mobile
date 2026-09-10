import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

/// The display name for a studio format, in the reader's language.
///
/// Free function rather than a method on the enum so the enum stays free of
/// anything to do with the UI, and free of a BuildContext.
String studioFormatLabel(AppLocalizations l10n, StudioFormat format) {
  switch (format) {
    case StudioFormat.docuseries:
      return l10n.studioFormatDocuseries;
    case StudioFormat.videocast:
      return l10n.studioFormatVideocasts;
    case StudioFormat.podcast:
      return l10n.studioFormatPodcasts;
    case StudioFormat.series:
      return l10n.studioFormatSeries;
    case StudioFormat.other:
      return l10n.studioFormatOther;
  }
}

/// The display name for a project's status, in the reader's language.
///
/// These three strings existed in the ARB long before anything rendered them:
/// the status chip on the listing was drawn from `index % 2`, so it alternated
/// down the page and neither of the two words it produced was a real status.
String studioStatusLabel(AppLocalizations l10n, StudioStatus status) {
  switch (status) {
    case StudioStatus.ongoing:
      return l10n.studioStatusOngoing;
    case StudioStatus.complete:
      return l10n.studioStatusComplete;
    case StudioStatus.upcoming:
      return l10n.studioStatusUpcoming;
  }
}
