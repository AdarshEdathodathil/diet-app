import 'package:clinical_dietitian_calculator/src/clinical_calculator.dart';
import 'package:clinical_dietitian_calculator/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = ClinicalCalculator();

  group('ClinicalCalculator', () {
    test('required test case A calculates the main example', () {
      final result = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 155,
          actualWeightKg: 55,
        ),
      );
      expect(result.heightM, closeTo(1.55, .0001));
      expect(result.bmi, closeTo(22.89, .01));
      expect(result.bmiClassification, 'Normal');
      expect(result.ibwKg, closeTo(54.05625, .0001));
      expect(result.calories, closeTo(1375, .001));
      expect(result.proteinGrams, closeTo(60.5, .001));
      expect(result.proteinEnergy, closeTo(242, .001));
      expect(result.choEnergy, closeTo(618.75, .001));
      expect(result.choGrams, closeTo(154.6875, .001));
      expect(result.remainingEnergy, closeTo(514.25, .001));
      expect(result.fatGrams, closeTo(57.1389, .001));
      expect(result.waterMl, closeTo(1650, .001));
      expect(result.errors, isEmpty);
    });

    test('required test case B recalculates CHO and residual fat', () {
      final at50 = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 155,
          actualWeightKg: 55,
          choPercent: 50,
        ),
      );
      expect(at50.choEnergy, closeTo(687.5, .001));
      expect(at50.choGrams, closeTo(171.875, .001));
      expect(at50.fatGrams, closeTo(49.5, .001));

      final at20 = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 155,
          actualWeightKg: 55,
          choPercent: 20,
        ),
      );
      expect(at20.choEnergy, closeTo(275, .001));
      expect(at20.choGrams, closeTo(68.75, .001));
      expect(at20.fatGrams, closeTo(95.3333, .001));
    });

    test('required test case C rejects negative fat', () {
      final result = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 155,
          actualWeightKg: 55,
          calorieFactor: 20,
          proteinFactor: 1.5,
          choPercent: 90,
        ),
      );
      expect(result.remainingEnergy, lessThan(0));
      expect(result.fatGrams, isNull);
      expect(result.errors, isNotEmpty);
    });

    test('required test case D handles zero values safely', () {
      final result = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 0,
          actualWeightKg: 0,
        ),
      );
      expect(result.bmi, isNull);
      expect(result.ibwKg, isNull);
      expect(result.calories, isNull);
      expect(result.errors, hasLength(2));
    });

    test('Mifflin-St Jeor female calculation is correct', () {
      final result = calculator.calculate(
        const AssessmentInput(
          age: 30,
          gender: Gender.female,
          heightCm: 155,
          actualWeightKg: 55,
          calorieMethod: CalorieMethod.mifflinStJeor,
        ),
      );
      expect(result.bmr, closeTo(1207.75, .001));
      expect(result.calories, closeTo(1449.3, .001));
    });

    test('adult Asian Indian BMI boundaries have no gaps', () {
      expect(ClinicalCalculator.classifyAdultBmi(18.49), 'Underweight');
      expect(ClinicalCalculator.classifyAdultBmi(18.5), 'Normal');
      expect(ClinicalCalculator.classifyAdultBmi(23), 'Overweight');
      expect(ClinicalCalculator.classifyAdultBmi(25), 'Obesity Class I');
      expect(ClinicalCalculator.classifyAdultBmi(30), 'Obesity Class II');
      expect(ClinicalCalculator.classifyAdultBmi(35), 'Obesity Class III');
    });
  });
}
