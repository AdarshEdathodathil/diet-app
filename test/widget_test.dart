import 'package:clinical_dietitian_calculator/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the three-step clinical workflow', (tester) async {
    await tester.pumpWidget(const ClinicalDietitianApp());
    expect(find.text('DT Haritha'), findsOneWidget);
    expect(find.text('Patient information'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Assessment'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
  });
}
