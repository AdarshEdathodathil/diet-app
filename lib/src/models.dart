enum Gender { male, female }

enum WeightBasis { actual, ideal, custom }

enum CalorieMethod { weightBased, mifflinStJeor }

extension GenderLabel on Gender {
  String get label => this == Gender.male ? 'Male' : 'Female';
}

extension WeightBasisLabel on WeightBasis {
  String get label => switch (this) {
    WeightBasis.actual => 'Actual body weight',
    WeightBasis.ideal => 'Ideal body weight',
    WeightBasis.custom => 'Custom weight',
  };
}

class AssessmentInput {
  const AssessmentInput({
    this.age,
    this.gender,
    this.heightCm,
    this.actualWeightKg,
    this.targetBmi = 22.5,
    this.manualIbwKg,
    this.calorieMethod = CalorieMethod.weightBased,
    this.calorieWeightBasis = WeightBasis.actual,
    this.calorieCustomWeightKg,
    this.calorieFactor = 25,
    this.activityFactor = 1.2,
    this.proteinWeightBasis = WeightBasis.actual,
    this.proteinCustomWeightKg,
    this.proteinFactor = 1.1,
    this.choPercent = 45,
    this.fibreGrams = 25,
    this.waterWeightBasis = WeightBasis.actual,
    this.waterCustomWeightKg,
    this.waterFactor = 30,
    this.manualWaterMl,
  });

  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? actualWeightKg;
  final double targetBmi;
  final double? manualIbwKg;
  final CalorieMethod calorieMethod;
  final WeightBasis calorieWeightBasis;
  final double? calorieCustomWeightKg;
  final double calorieFactor;
  final double activityFactor;
  final WeightBasis proteinWeightBasis;
  final double? proteinCustomWeightKg;
  final double proteinFactor;
  final double choPercent;
  final double fibreGrams;
  final WeightBasis waterWeightBasis;
  final double? waterCustomWeightKg;
  final double waterFactor;
  final double? manualWaterMl;
}

class AssessmentResult {
  const AssessmentResult({
    this.heightM,
    this.bmi,
    this.bmiClassification,
    this.calculatedIbwKg,
    this.ibwKg,
    this.calorieWeightKg,
    this.bmr,
    this.calories,
    this.proteinWeightKg,
    this.proteinGrams,
    this.proteinEnergy,
    this.choEnergy,
    this.choGrams,
    this.remainingEnergy,
    this.fatGrams,
    this.waterWeightKg,
    this.waterMl,
    this.macroEnergy,
    this.macroDifference,
    this.errors = const [],
    this.warnings = const [],
  });

  final double? heightM;
  final double? bmi;
  final String? bmiClassification;
  final double? calculatedIbwKg;
  final double? ibwKg;
  final double? calorieWeightKg;
  final double? bmr;
  final double? calories;
  final double? proteinWeightKg;
  final double? proteinGrams;
  final double? proteinEnergy;
  final double? choEnergy;
  final double? choGrams;
  final double? remainingEnergy;
  final double? fatGrams;
  final double? waterWeightKg;
  final double? waterMl;
  final double? macroEnergy;
  final double? macroDifference;
  final List<String> errors;
  final List<String> warnings;

  bool get hasValidMacros => fatGrams != null && errors.isEmpty;
}
