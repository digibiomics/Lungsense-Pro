import 'package:equatable/equatable.dart';

/// The ten items of `SessionSymptomsIn`, in the server's order. Each is
/// rated 0 (none) to 3 (severe) and all ten are required.
enum SymptomKey {
  breathlessness('breathlessness'),
  activityLimitation('activity_limitation'),
  changeFromUsual('change_from_usual'),
  fever('fever'),
  chestTightness('chest_tightness'),
  chestDiscomfortBreathing('chest_discomfort_breathing'),
  wheezing('wheezing'),
  coughSeverity('cough_severity'),
  mucus('mucus'),
  sleepDisruption('sleep_disruption');

  const SymptomKey(this.api);
  final String api;
}

/// Ratings for one session. A missing key means "not rated"; the app never
/// fills in a default.
class SymptomRatings extends Equatable {
  const SymptomRatings(this.values, {this.checkinDate});

  final Map<SymptomKey, int> values;
  final DateTime? checkinDate;

  static const empty = SymptomRatings({});

  int? operator [](SymptomKey k) => values[k];

  bool get isComplete => SymptomKey.values.every(values.containsKey);
  int get ratedCount => values.length;

  /// Highest rating given, or null when nothing is rated.
  int? get highest =>
      values.isEmpty ? null : values.values.reduce((a, b) => a > b ? a : b);

  SymptomRatings withRating(SymptomKey k, int v) {
    assert(v >= 0 && v <= 3);
    return SymptomRatings({...values, k: v}, checkinDate: checkinDate);
  }

  @override
  List<Object?> get props => [values, checkinDate];
}
