import '../../domain/entities/symptoms.dart';

/// Labels for the 0–3 scale (Symptoms.dc.html).
const severityNames = ['None', 'Mild', 'Moderate', 'Severe'];

/// Title, question and per-level descriptors of each symptom.
///
/// OPEN QUESTION (KNOWN_ISSUES KI-19): the handoff only defines the
/// description and the four level descriptors for Breathlessness and
/// Activity limitation. The other eight have no approved wording and the
/// API does not serve any, so they show the title only. Fill [description]
/// and [levels] here once the product owner supplies the text; nothing else
/// needs to change.
class SymptomCopy {
  const SymptomCopy(this.title, {this.description, this.levels});
  final String title;
  final String? description;

  /// Exactly four entries (0–3) when set.
  final List<String>? levels;
}

const Map<SymptomKey, SymptomCopy> symptomCopy = {
  SymptomKey.breathlessness: SymptomCopy(
    'Breathlessness',
    description: 'Shortness of breath or difficulty breathing',
    levels: [
      'Breathing normal and easy',
      'Slight shortness with a fast walk',
      'Noticeable breathlessness on stairs',
      'Breathless even at rest',
    ],
  ),
  SymptomKey.activityLimitation: SymptomCopy(
    'Activity limitation',
    description: 'Trouble walking, climbing stairs or with routine tasks',
    levels: [
      'No limitations at all',
      'Slight fatigue with heavy work',
      'Needs frequent rest during daily tasks',
      'Unable to do normal daily activities',
    ],
  ),
  SymptomKey.changeFromUsual: SymptomCopy('Change from usual'),
  SymptomKey.fever: SymptomCopy('Fever'),
  SymptomKey.chestTightness: SymptomCopy('Chest tightness'),
  SymptomKey.chestDiscomfortBreathing: SymptomCopy(
    'Chest discomfort when breathing',
  ),
  SymptomKey.wheezing: SymptomCopy('Wheezing'),
  SymptomKey.coughSeverity: SymptomCopy('Cough'),
  SymptomKey.mucus: SymptomCopy('Mucus'),
  SymptomKey.sleepDisruption: SymptomCopy('Sleep disruption'),
};

String ratingLabel(int v) => '$v · ${severityNames[v]}';
