import 'package:clinical_dietitian_calculator/src/app.dart';
import 'package:clinical_dietitian_calculator/src/assessment_repository.dart';
import 'package:clinical_dietitian_calculator/src/patient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository extends AssessmentRepository {
  @override
  Future<DashboardStats> dashboardStats() async =>
      const DashboardStats(patients: 0, assessments: 0, drafts: 0);

  @override
  Future<List<Patient>> searchPatients(
    String query, {
    bool includeArchived = false,
  }) async => [];
}

void main() {
  testWidgets('renders the patient dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ClinicalDietitianApp(repository: _FakeRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dt Haritha'), findsOneWidget);
    expect(find.text('Patients'), findsWidgets);
    expect(find.text('Assessments'), findsOneWidget);
    expect(find.text('New patient'), findsOneWidget);
  });
}
