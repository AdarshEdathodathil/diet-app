import 'models.dart';

class ClinicalCalculator {
  const ClinicalCalculator();

  AssessmentResult calculate(AssessmentInput input) {
    final errors = <String>[];
    final warnings = <String>[];
    final validHeight = _positive(input.heightCm);
    final validWeight = _positive(input.actualWeightKg);
    final heightM = validHeight ? input.heightCm! / 100 : null;
    final bmi = heightM != null && validWeight
        ? input.actualWeightKg! / (heightM * heightM)
        : null;

    String? classification;
    if (bmi != null) {
      if (input.age == null || input.age! < 18) {
        warnings.add(
          'Adult BMI classification is not applied to patients under 18.',
        );
      } else {
        classification = classifyAdultBmi(bmi);
      }
    }
    if (!validHeight && input.heightCm != null) {
      errors.add('Height must be greater than zero.');
    }
    if (!validWeight && input.actualWeightKg != null) {
      errors.add('Weight must be greater than zero.');
    }
    if (input.age != null && input.age! <= 0) {
      errors.add('Age must be a positive whole number.');
    }
    if (input.choPercent < 0 || input.choPercent > 100) {
      errors.add('CHO percentage must be between 0 and 100.');
    }

    final calculatedIbw = heightM == null || input.targetBmi <= 0
        ? null
        : input.targetBmi * heightM * heightM;
    final ibw = _positive(input.manualIbwKg)
        ? input.manualIbwKg
        : calculatedIbw;
    final calorieWeight = _weightFor(
      input.calorieWeightBasis,
      actual: input.actualWeightKg,
      ideal: ibw,
      custom: input.calorieCustomWeightKg,
    );

    double? bmr;
    double? calories;
    if (input.calorieMethod == CalorieMethod.weightBased) {
      if (_positive(calorieWeight) && input.calorieFactor > 0) {
        calories = calorieWeight! * input.calorieFactor;
      }
    } else if (_positive(calorieWeight) &&
        validHeight &&
        input.age != null &&
        input.age! > 0 &&
        input.gender != null &&
        input.activityFactor > 0) {
      bmr =
          (10 * calorieWeight!) +
          (6.25 * input.heightCm!) -
          (5 * input.age!) +
          (input.gender == Gender.male ? 5 : -161);
      calories = bmr * input.activityFactor;
    }

    final proteinWeight = _weightFor(
      input.proteinWeightBasis,
      actual: input.actualWeightKg,
      ideal: ibw,
      custom: input.proteinCustomWeightKg,
    );
    final proteinGrams = _positive(proteinWeight) && input.proteinFactor > 0
        ? proteinWeight! * input.proteinFactor
        : null;
    final proteinEnergy = proteinGrams == null ? null : proteinGrams * 4;
    final choEnergy =
        calories == null || input.choPercent < 0 || input.choPercent > 100
        ? null
        : calories * input.choPercent / 100;
    final choGrams = choEnergy == null ? null : choEnergy / 4;

    double? remainingEnergy;
    double? fatGrams;
    double? macroEnergy;
    double? macroDifference;
    if (calories != null && proteinEnergy != null && choEnergy != null) {
      remainingEnergy = calories - proteinEnergy - choEnergy;
      if (remainingEnergy < 0) {
        errors.add(
          'Protein and CHO energy exceed the calorie target. Review the selected factors.',
        );
      } else {
        fatGrams = remainingEnergy / 9;
        macroEnergy = proteinEnergy + choEnergy + fatGrams * 9;
        macroDifference = macroEnergy - calories;
        if (macroDifference.abs() > 0.5) {
          warnings.add('Macro energy differs from the calorie target.');
        }
      }
    }

    final waterWeight = _weightFor(
      input.waterWeightBasis,
      actual: input.actualWeightKg,
      ideal: null,
      custom: input.waterCustomWeightKg,
    );
    final calculatedWater = _positive(waterWeight) && input.waterFactor > 0
        ? waterWeight! * input.waterFactor
        : null;
    final water = _positive(input.manualWaterMl)
        ? input.manualWaterMl
        : calculatedWater;
    if (input.manualIbwKg != null) {
      warnings.add('IBW is manually overridden.');
    }
    if (input.manualWaterMl != null) {
      warnings.add('Water target is manually adjusted.');
    }

    return AssessmentResult(
      heightM: heightM,
      bmi: bmi,
      bmiClassification: classification,
      calculatedIbwKg: calculatedIbw,
      ibwKg: ibw,
      calorieWeightKg: calorieWeight,
      bmr: bmr,
      calories: calories,
      proteinWeightKg: proteinWeight,
      proteinGrams: proteinGrams,
      proteinEnergy: proteinEnergy,
      choEnergy: choEnergy,
      choGrams: choGrams,
      remainingEnergy: remainingEnergy,
      fatGrams: fatGrams,
      waterWeightKg: waterWeight,
      waterMl: water,
      macroEnergy: macroEnergy,
      macroDifference: macroDifference,
      errors: errors,
      warnings: warnings,
    );
  }

  static String classifyAdultBmi(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 23) return 'Normal';
    if (bmi < 25) return 'Overweight';
    if (bmi < 30) return 'Obesity Class I';
    if (bmi < 35) return 'Obesity Class II';
    return 'Obesity Class III';
  }

  static bool _positive(double? value) => value != null && value > 0;

  static double? _weightFor(
    WeightBasis basis, {
    required double? actual,
    required double? ideal,
    required double? custom,
  }) => switch (basis) {
    WeightBasis.actual => _positive(actual) ? actual : null,
    WeightBasis.ideal => _positive(ideal) ? ideal : null,
    WeightBasis.custom => _positive(custom) ? custom : null,
  };
}
