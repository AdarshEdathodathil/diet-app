import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';

class PdfReportService {
  const PdfReportService();

  Future<Uint8List> build({
    required AssessmentInput input,
    required AssessmentResult result,
    required List<String> diagnoses,
    required bool approved,
    required String notes,
  }) async {
    final document = pw.Document(
      title: 'DT Haritha Assessment',
      author: 'DT Haritha',
    );
    final now = DateTime.now();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal700)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DT Haritha',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
              pw.Text(
                'Assessment report',
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Calculation and documentation aid',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          _status(approved),
          pw.SizedBox(height: 16),
          _section('Patient information', [
            _row('Assessment date', _date(now)),
            if (input.age != null) _row('Age', '${input.age} years'),
            if (input.gender != null) _row('Gender', input.gender!.label),
            if (diagnoses.isNotEmpty) _row('Diagnosis', diagnoses.join(', ')),
          ]),
          _section('Anthropometric assessment', [
            if (input.heightCm != null)
              _row('Height', '${_n(input.heightCm, 1)} cm'),
            if (input.actualWeightKg != null)
              _row('Actual weight', '${_n(input.actualWeightKg, 1)} kg'),
            if (result.bmi != null) _row('BMI', '${_n(result.bmi, 2)} kg/m2'),
            if (result.bmiClassification != null)
              _row('BMI classification', result.bmiClassification!),
            _row('Target BMI', _n(input.targetBmi, 1)),
            if (result.ibwKg != null)
              _row(
                'Ideal body weight',
                '${_n(result.ibwKg, 1)} kg${input.manualIbwKg != null ? ' (manual override)' : ''}',
              ),
          ]),
          _section('Nutrition requirements', [
            _row(
              'Calorie method',
              input.calorieMethod == CalorieMethod.weightBased
                  ? 'Weight-based'
                  : 'Mifflin-St Jeor',
            ),
            _row('Calorie weight basis', input.calorieWeightBasis.label),
            if (input.calorieMethod == CalorieMethod.weightBased)
              _row('Calorie factor', '${_n(input.calorieFactor, 2)} kcal/kg'),
            if (result.bmr != null)
              _row('BMR', '${_n(result.bmr, 1)} kcal/day'),
            if (input.calorieMethod == CalorieMethod.mifflinStJeor)
              _row('Activity factor', _n(input.activityFactor, 3)),
            if (result.calories != null)
              _row('Total calories', '${_n(result.calories, 0)} kcal/day'),
            _row('Protein weight basis', input.proteinWeightBasis.label),
            _row('Protein factor', '${_n(input.proteinFactor, 2)} g/kg'),
            if (result.proteinGrams != null)
              _row(
                'Protein',
                '${_n(result.proteinGrams, 1)} g/day (${_n(result.proteinEnergy, 1)} kcal)',
              ),
            _row('CHO percentage', '${_n(input.choPercent, 1)}%'),
            if (result.choGrams != null)
              _row(
                'Carbohydrate',
                '${_n(result.choGrams, 1)} g/day (${_n(result.choEnergy, 1)} kcal)',
              ),
            if (result.fatGrams != null)
              _row('Residual fat', '${_n(result.fatGrams, 1)} g/day'),
            _row('Fibre', '${_n(input.fibreGrams, 1)} g/day'),
            if (result.waterMl != null)
              _row(
                'Water',
                '${_n(result.waterMl, 0)} ml/day${input.manualWaterMl != null ? ' (manual adjustment)' : ''}',
              ),
          ]),
          if (notes.trim().isNotEmpty)
            _section('Clinical notes', [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Text(notes.trim()),
              ),
            ]),
          _section('Energy validation', [
            if (result.macroEnergy != null)
              _row('Total macro energy', '${_n(result.macroEnergy, 1)} kcal'),
            if (result.calories != null)
              _row(
                'Prescribed calorie target',
                '${_n(result.calories, 1)} kcal',
              ),
            if (result.macroDifference != null)
              _row('Difference', '${_n(result.macroDifference, 2)} kcal'),
          ]),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.amber50,
            child: pw.Text(
              'Clinical note: This report is a calculation and documentation aid. Final requirements must be reviewed and approved by a qualified dietitian.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _section(String title, List<pw.Widget> rows) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          color: PdfColors.teal50,
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 4),
          child: pw.Column(children: rows),
        ),
      ],
    ),
  );

  pw.Widget _row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 155,
          child: pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    ),
  );

  pw.Widget _status(bool approved) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: pw.BoxDecoration(
      color: approved ? PdfColors.green50 : PdfColors.orange50,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text(
      approved
          ? 'DIETITIAN REVIEWED AND APPROVED'
          : 'DIETITIAN APPROVAL PENDING',
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: approved ? PdfColors.green800 : PdfColors.orange800,
      ),
    ),
  );

  String _n(double? value, int decimals) =>
      value?.toStringAsFixed(decimals) ?? '-';

  String _date(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
