import 'package:equatable/equatable.dart';

/// One figure on the Impact rail — "50+ films", "€500K raised".
///
/// `label` is a plain TEXT column, not the JSONB every editorial field uses,
/// so it is the same in all three languages. That is a limitation of the
/// existing table rather than a decision made here.
class ImpactStat extends Equatable {
  final String id;
  final String label;
  final double value;

  /// "+", "K", "%" — whatever the editor typed after the number.
  final String suffix;

  final String imageUrl;

  /// The dashboard's icon name — "Heart", "Globe", "GraduationCap"… one of
  /// the eight in `metricIconOptions` on /admin/impact.
  ///
  /// A name, not a codepoint, for the same reason the Home shortcut tiles
  /// store names: a codepoint would tie an editor's dropdown to the exact
  /// Material font shipped in one build of the app.
  final String icon;

  const ImpactStat({
    required this.id,
    required this.label,
    required this.value,
    this.suffix = '',
    this.imageUrl = '',
    this.icon = '',
  });

  /// The figure as it should read on the card.
  ///
  /// Whole numbers lose their decimal — "50" rather than "50.0", which is
  /// what an editor typing 50 into a DECIMAL column expects to see.
  String get display {
    final n = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$n$suffix';
  }

  @override
  List<Object?> get props => [id, label, value, suffix, imageUrl, icon];
}
