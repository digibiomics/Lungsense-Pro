import '../../../../core/routing/routes.dart';

/// Who is collecting: a doctor for a patient, or a patient for themself
/// ("patient check-in reuses screens 17–23 with patient copy").
enum CollectionMode {
  doctor,
  patient;

  String sessionPath(String id) => switch (this) {
    CollectionMode.doctor => Routes.doctorSessionFor(id),
    CollectionMode.patient => Routes.patientCheckInFor(id),
  };

  String stepPath(String id, CollectionRoute step) =>
      '${sessionPath(id)}/${step.segment}';

  /// Where "Back to dashboard" / "Done" goes.
  String get home => switch (this) {
    CollectionMode.doctor => Routes.doctorDashboard,
    CollectionMode.patient => Routes.patientHome,
  };

  bool get isPatient => this == CollectionMode.patient;
}

/// The screens under a session.
enum CollectionRoute {
  cough('cough'),
  breathing('breathing'),
  symptoms('symptoms'),
  context('context'),
  review('review'),
  submit('submit');

  const CollectionRoute(this.segment);
  final String segment;
}
