import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'assessment_repository.dart';
import 'app_settings.dart';
import 'clinical_calculator.dart';
import 'models.dart';
import 'pdf_report_service.dart';
import 'patient.dart';
import 'saved_assessment.dart';
import 'saved_assessments_screen.dart';

const diagnosisGroups = <String, List<String>>{
  'Weight management': [
    'Weight Loss',
    'Weight Gain',
    'Normal Weight',
    'Obesity',
    'Underweight',
  ],
  'Diabetes': ['Type 1 Diabetes Mellitus', 'Type 2 Diabetes Mellitus'],
  'Hormonal disorders': ['PCOD / PCOS', 'Hypothyroidism', 'Hyperthyroidism'],
};

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    super.key,
    this.repository,
    this.patient,
    this.initialAssessment,
    this.duplicateInitialAssessment = false,
    this.settings,
  });

  final AssessmentRepository? repository;
  final Patient? patient;
  final SavedAssessment? initialAssessment;
  final bool duplicateInitialAssessment;
  final AppSettings? settings;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _calculator = const ClinicalCalculator();
  final _pdfService = const PdfReportService();
  late final AssessmentRepository _repository =
      widget.repository ?? AssessmentRepository();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetBmi = TextEditingController(text: '22.5');
  final _manualIbw = TextEditingController();
  final _calorieCustomWeight = TextEditingController();
  final _calorieFactor = TextEditingController(text: '25');
  final _activityFactor = TextEditingController(text: '1.2');
  final _proteinCustomWeight = TextEditingController();
  final _proteinFactor = TextEditingController(text: '1.1');
  final _choPercent = TextEditingController(text: '45');
  final _fibre = TextEditingController(text: '25');
  final _waterCustomWeight = TextEditingController();
  final _waterFactor = TextEditingController(text: '30');
  final _manualWater = TextEditingController();
  final _notes = TextEditingController();

  late final List<TextEditingController> _controllers = [
    _age,
    _height,
    _weight,
    _targetBmi,
    _manualIbw,
    _calorieCustomWeight,
    _calorieFactor,
    _activityFactor,
    _proteinCustomWeight,
    _proteinFactor,
    _choPercent,
    _fibre,
    _waterCustomWeight,
    _waterFactor,
    _manualWater,
    _notes,
  ];
  int _step = 0;
  Gender? _gender;
  final _diagnoses = <String>{};
  CalorieMethod _calorieMethod = CalorieMethod.weightBased;
  WeightBasis _calorieBasis = WeightBasis.actual;
  WeightBasis _proteinBasis = WeightBasis.actual;
  WeightBasis _waterBasis = WeightBasis.actual;
  bool _approved = false;
  bool _showEquations = false;
  int? _recordId;
  DateTime? _createdAt;
  int? _patientId;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patient?.id;
    if (widget.patient?.age != null) _age.text = '${widget.patient!.age}';
    if (widget.patient?.gender == 'Male') _gender = Gender.male;
    if (widget.patient?.gender == 'Female') _gender = Gender.female;
    for (final controller in _controllers) {
      controller.addListener(_refresh);
    }
    if (widget.initialAssessment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAssessment(
          widget.initialAssessment!,
          duplicate: widget.duplicateInitialAssessment,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _approved = false);
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 700), _saveDraft);
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim());
  int? _integer(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  AssessmentInput get _input => AssessmentInput(
    age: _integer(_age),
    gender: _gender,
    heightCm: _number(_height),
    actualWeightKg: _number(_weight),
    targetBmi: _number(_targetBmi) ?? 0,
    manualIbwKg: _number(_manualIbw),
    calorieMethod: _calorieMethod,
    calorieWeightBasis: _calorieBasis,
    calorieCustomWeightKg: _number(_calorieCustomWeight),
    calorieFactor: _number(_calorieFactor) ?? 0,
    activityFactor: _number(_activityFactor) ?? 0,
    proteinWeightBasis: _proteinBasis,
    proteinCustomWeightKg: _number(_proteinCustomWeight),
    proteinFactor: _number(_proteinFactor) ?? 0,
    choPercent: _number(_choPercent) ?? -1,
    fibreGrams: _number(_fibre) ?? 0,
    waterWeightBasis: _waterBasis,
    waterCustomWeightKg: _number(_waterCustomWeight),
    waterFactor: _number(_waterFactor) ?? 0,
    manualWaterMl: _number(_manualWater),
  );

  @override
  Widget build(BuildContext context) {
    final result = _calculator.calculate(_input);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: const Row(
          children: [
            _BrandMark(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dt Haritha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  Text(
                    'Dietitian workspace',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB9D8D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const _OfflineBadge(),
          IconButton(
            onPressed: _openPresets,
            tooltip: 'Clinical presets',
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            onPressed: _openSavedAssessments,
            tooltip: 'Saved assessments',
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: 'New assessment',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          _StepHeader(
            step: _step,
            onChanged: (value) => setState(() => _step = value),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: switch (_step) {
                    0 => _patientStep(),
                    1 => _anthropometryStep(result),
                    _ => _nutritionStep(result),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        step: _step,
        canContinue: _canContinue,
        approved: _approved,
        onBack: () => setState(() => _step--),
        onNext: () => setState(() => _step++),
        onApprove: result.hasValidMacros && _diagnoses.isNotEmpty
            ? () => setState(() => _approved = !_approved)
            : null,
        onSave: _approved ? () => _saveAssessment(result) : null,
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    0 => (_integer(_age) ?? 0) > 0 && _gender != null,
    1 => (_number(_height) ?? 0) > 0 && (_number(_weight) ?? 0) > 0,
    _ => true,
  };

  Widget _patientStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _PageIntro(
        'STEP 1 OF 3',
        'Patient information',
        'Only the minimum information required for this assessment.',
      ),
      _SectionCard(
        title: 'Patient details',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              controller: _age,
              label: 'Age',
              suffix: 'years',
              integer: true,
              min: 1,
              max: 120,
            ),
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: Gender.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _gender = value;
                _approved = false;
              }),
            ),
          ],
        ),
      ),
      _SectionCard(
        title: 'Diagnosis',
        subtitle:
            'Select one or more. Diagnoses never set prescriptions automatically.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _chooseDiagnoses,
              icon: const Icon(Icons.search),
              label: const Text('Search and select diagnoses'),
            ),
            if (_diagnoses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'At least one diagnosis is recommended.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _diagnoses
                      .map(
                        (item) => InputChip(
                          label: Text(item),
                          onDeleted: () =>
                              setState(() => _diagnoses.remove(item)),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
      const _Notice(
        Icons.health_and_safety_outlined,
        'This tool supports qualified dietitians and does not autonomously prescribe treatment.',
      ),
    ],
  );

  Widget _anthropometryStep(AssessmentResult result) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _PageIntro(
        'STEP 2 OF 3',
        'Anthropometric assessment',
        'BMI and ideal body weight update as measurements change.',
      ),
      _SectionCard(
        title: 'Measurements',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              controller: _height,
              label: 'Height',
              suffix: 'cm',
              min: 50,
              max: 250,
            ),
            _NumberField(
              controller: _weight,
              label: 'Actual weight',
              suffix: 'kg',
              min: 2,
              max: 500,
            ),
          ],
        ),
      ),
      _SectionCard(
        title: 'Calculated assessment',
        child: _MetricGrid([
          _Metric('Height', _format(result.heightM, 'm', 2)),
          _Metric('BMI', _format(result.bmi, 'kg/m²', 2)),
          _Metric('Classification', result.bmiClassification ?? '—'),
          _Metric('Ideal body weight', _format(result.ibwKg, 'kg', 1)),
        ]),
      ),
      _SectionCard(
        title: 'IBW settings',
        subtitle:
            'The default uses target BMI 22.5. An override is recorded clearly.',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              controller: _targetBmi,
              label: 'Target BMI',
              suffix: 'kg/m²',
              min: 10,
              max: 60,
            ),
            _NumberField(
              controller: _manualIbw,
              label: 'Manual IBW override',
              suffix: 'kg',
              optional: true,
            ),
          ],
        ),
      ),
      ..._messages(result),
    ],
  );

  Widget _nutritionStep(AssessmentResult result) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _PageIntro(
        'STEP 3 OF 3',
        'Nutrition calculator',
        'Review every method, weight basis and factor before approval.',
      ),
      _SectionCard(
        title: 'Energy',
        child: Column(
          children: [
            SegmentedButton<CalorieMethod>(
              segments: const [
                ButtonSegment(
                  value: CalorieMethod.weightBased,
                  label: Text('Weight-based'),
                ),
                ButtonSegment(
                  value: CalorieMethod.mifflinStJeor,
                  label: Text('Mifflin–St Jeor'),
                ),
              ],
              selected: {_calorieMethod},
              onSelectionChanged: (value) => setState(() {
                _calorieMethod = value.first;
                _approved = false;
              }),
            ),
            const SizedBox(height: 16),
            _BasisPicker(
              label: 'Calorie weight basis',
              value: _calorieBasis,
              allowIdeal: true,
              onChanged: (value) => setState(() => _calorieBasis = value),
            ),
            if (_calorieBasis == WeightBasis.custom) ...[
              const SizedBox(height: 12),
              _NumberField(
                controller: _calorieCustomWeight,
                label: 'Custom calorie weight',
                suffix: 'kg',
              ),
            ],
            const SizedBox(height: 16),
            if (_calorieMethod == CalorieMethod.weightBased)
              _FactorField(
                controller: _calorieFactor,
                label: 'Calorie factor',
                suffix: 'kcal/kg',
                presets: const [20, 25, 30],
              )
            else
              _FactorField(
                controller: _activityFactor,
                label: 'Activity factor',
                suffix: '',
                presets: const [1.2, 1.375, 1.55, 1.725, 1.9],
              ),
          ],
        ),
      ),
      _SectionCard(
        title: 'Protein and carbohydrate',
        child: Column(
          children: [
            _BasisPicker(
              label: 'Protein weight basis',
              value: _proteinBasis,
              allowIdeal: true,
              onChanged: (value) => setState(() => _proteinBasis = value),
            ),
            if (_proteinBasis == WeightBasis.custom) ...[
              const SizedBox(height: 12),
              _NumberField(
                controller: _proteinCustomWeight,
                label: 'Custom protein weight',
                suffix: 'kg',
              ),
            ],
            const SizedBox(height: 16),
            _FactorField(
              controller: _proteinFactor,
              label: 'Protein factor',
              suffix: 'g/kg',
              presets: const [0.8, 1, 1.1, 1.2, 1.5],
            ),
            const SizedBox(height: 16),
            _FactorField(
              controller: _choPercent,
              label: 'CHO percentage',
              suffix: '%',
              presets: const [20, 30, 40, 45, 50, 55],
            ),
          ],
        ),
      ),
      _SectionCard(
        title: 'Fibre and water',
        child: Column(
          children: [
            _FactorField(
              controller: _fibre,
              label: 'Fibre target',
              suffix: 'g/day',
              presets: const [20, 25, 30],
            ),
            const SizedBox(height: 16),
            _BasisPicker(
              label: 'Water weight basis',
              value: _waterBasis,
              allowIdeal: false,
              onChanged: (value) => setState(() => _waterBasis = value),
            ),
            if (_waterBasis == WeightBasis.custom) ...[
              const SizedBox(height: 12),
              _NumberField(
                controller: _waterCustomWeight,
                label: 'Custom water weight',
                suffix: 'kg',
              ),
            ],
            const SizedBox(height: 16),
            _FactorField(
              controller: _waterFactor,
              label: 'Water factor',
              suffix: 'ml/kg',
              presets: const [25, 30, 35],
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _manualWater,
              label: 'Manual water adjustment',
              suffix: 'ml/day',
              optional: true,
            ),
          ],
        ),
      ),
      _SectionCard(
        title: 'Clinical notes',
        subtitle:
            'Optional notes, observations or follow-up instructions for this assessment.',
        child: TextField(
          controller: _notes,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText:
                'Add clinical observations, considerations or follow-up notes…',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(Icons.edit_note_rounded),
            ),
          ),
        ),
      ),
      ..._messages(result),
      _summaryCard(result),
    ],
  );

  Widget _summaryCard(AssessmentResult result) => _SectionCard(
    title: 'Assessment summary',
    subtitle: _approved
        ? 'Reviewed and approved by dietitian'
        : 'Dietitian approval required',
    trailing: Icon(
      _approved ? Icons.verified : Icons.pending_outlined,
      color: _approved ? Colors.green : Colors.orange,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid([
          _Metric('Calories', _format(result.calories, 'kcal/day', 0)),
          _Metric('Protein', _format(result.proteinGrams, 'g/day', 1)),
          _Metric('CHO', _format(result.choGrams, 'g/day', 1)),
          _Metric('Fat', _format(result.fatGrams, 'g/day', 1)),
          _Metric('Fibre', _format(_number(_fibre), 'g/day', 0)),
          _Metric('Water', _format(result.waterMl, 'ml/day', 0)),
        ]),
        if (_approved) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _printReport(result),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print report'),
              ),
              OutlinedButton.icon(
                onPressed: () => _shareReport(result),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share PDF'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _showEquations = !_showEquations),
          icon: Icon(
            _showEquations ? Icons.expand_less : Icons.calculate_outlined,
          ),
          label: Text(
            _showEquations
                ? 'Hide calculation details'
                : 'View calculation details',
          ),
        ),
        if (_showEquations) ...[
          const Divider(),
          _Equation(
            'Calories',
            _calorieMethod == CalorieMethod.weightBased
                ? '${_format(result.calorieWeightKg, 'kg', 2)} × ${_calorieFactor.text} kcal/kg'
                : 'BMR ${_format(result.bmr, 'kcal', 1)} × ${_activityFactor.text}',
          ),
          _Equation(
            'Protein',
            '${_format(result.proteinWeightKg, 'kg', 2)} × ${_proteinFactor.text} g/kg = ${_format(result.proteinGrams, 'g', 2)}',
          ),
          _Equation(
            'CHO',
            '${_format(result.calories, 'kcal', 2)} × ${_choPercent.text}% ÷ 4 = ${_format(result.choGrams, 'g', 2)}',
          ),
          _Equation(
            'Residual fat',
            '[Calories − (${_format(result.proteinEnergy, 'protein kcal', 2)} + ${_format(result.choEnergy, 'CHO kcal', 2)})] ÷ 9',
          ),
          _Equation(
            'Macro validation',
            '${_format(result.macroEnergy, 'kcal', 2)} total; ${_format(result.macroDifference, 'kcal difference', 2)}',
          ),
        ],
      ],
    ),
  );

  List<Widget> _messages(AssessmentResult result) => [
    for (final error in result.errors)
      _Notice(Icons.error_outline, error, error: true),
    for (final warning in result.warnings)
      _Notice(Icons.warning_amber_rounded, warning),
  ];

  Future<void> _chooseDiagnoses() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _DiagnosisDialog(initial: _diagnoses),
    );
    if (selected != null) {
      setState(() {
        _diagnoses
          ..clear()
          ..addAll(selected);
        _approved = false;
      });
    }
  }

  Future<void> _saveAssessment(AssessmentResult result) async {
    final now = DateTime.now();
    final assessment = SavedAssessment(
      id: _recordId,
      patientId: _patientId,
      createdAt: _createdAt ?? now,
      updatedAt: now,
      age: _integer(_age)!,
      gender: _gender!.label,
      diagnoses: _diagnoses.toList(),
      bmi: result.bmi,
      calories: result.calories,
      approved: true,
      payload: {
        'age': _age.text,
        'gender': _gender!.name,
        'diagnoses': _diagnoses.toList(),
        'height': _height.text,
        'weight': _weight.text,
        'targetBmi': _targetBmi.text,
        'manualIbw': _manualIbw.text,
        'calorieMethod': _calorieMethod.name,
        'calorieBasis': _calorieBasis.name,
        'calorieCustomWeight': _calorieCustomWeight.text,
        'calorieFactor': _calorieFactor.text,
        'activityFactor': _activityFactor.text,
        'proteinBasis': _proteinBasis.name,
        'proteinCustomWeight': _proteinCustomWeight.text,
        'proteinFactor': _proteinFactor.text,
        'choPercent': _choPercent.text,
        'fibre': _fibre.text,
        'waterBasis': _waterBasis.name,
        'waterCustomWeight': _waterCustomWeight.text,
        'waterFactor': _waterFactor.text,
        'manualWater': _manualWater.text,
        'notes': _notes.text.trim(),
        'calculatedIbwKg': result.ibwKg,
        'bmrKcal': result.bmr,
        'proteinGrams': result.proteinGrams,
        'carbohydrateGrams': result.choGrams,
        'fatGrams': result.fatGrams,
        'waterMl': result.waterMl,
        'macroEnergyKcal': result.macroEnergy,
        'macroDifferenceKcal': result.macroDifference,
        'warnings': result.warnings,
        'approvalTimestamp': now.toIso8601String(),
      },
    );
    try {
      final id = await _repository.save(assessment);
      if (!mounted) return;
      setState(() {
        _recordId = id;
        _createdAt ??= now;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assessment #$id saved on this device.')),
      );
      await _repository.deleteDraft(_draftKey);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The assessment could not be saved locally.'),
        ),
      );
    }
  }

  Future<void> _printReport(AssessmentResult result) async {
    try {
      final bytes = await _pdfService.build(
        input: _input,
        result: result,
        diagnoses: _diagnoses.toList(),
        approved: _approved,
        notes: _notes.text.trim(),
        patient: widget.patient,
        assessmentId: _recordId,
        clinicName: widget.settings?.clinicName ?? '',
        dietitianName: widget.settings?.dietitianName ?? 'Dt Haritha',
        credentials: widget.settings?.credentials ?? '',
      );
      await Printing.layoutPdf(
        name: _reportFilename,
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The PDF report could not be printed.')),
      );
    }
  }

  Future<void> _shareReport(AssessmentResult result) async {
    try {
      final bytes = await _pdfService.build(
        input: _input,
        result: result,
        diagnoses: _diagnoses.toList(),
        approved: _approved,
        notes: _notes.text.trim(),
        patient: widget.patient,
        assessmentId: _recordId,
        clinicName: widget.settings?.clinicName ?? '',
        dietitianName: widget.settings?.dietitianName ?? 'Dt Haritha',
        credentials: widget.settings?.credentials ?? '',
      );
      await Printing.sharePdf(bytes: bytes, filename: _reportFilename);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The PDF report could not be shared.')),
      );
    }
  }

  Future<void> _openSavedAssessments() async {
    final record = await Navigator.push<SavedAssessment>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedAssessmentsScreen(repository: _repository),
      ),
    );
    if (record != null) _loadAssessment(record);
  }

  String get _reportFilename {
    final identifier = widget.patient?.opNumber.trim().isNotEmpty == true
        ? widget.patient!.opNumber.trim()
        : 'patient_${_patientId ?? 'new'}';
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '${identifier}_${date}_assessment.pdf'.replaceAll(
      RegExp(r'[^A-Za-z0-9_.-]'),
      '_',
    );
  }

  void _loadAssessment(SavedAssessment record, {bool duplicate = false}) {
    final data = record.payload;
    void setText(TextEditingController controller, String key) {
      controller.text = data[key]?.toString() ?? '';
    }

    setText(_age, 'age');
    setText(_height, 'height');
    setText(_weight, 'weight');
    setText(_targetBmi, 'targetBmi');
    setText(_manualIbw, 'manualIbw');
    setText(_calorieCustomWeight, 'calorieCustomWeight');
    setText(_calorieFactor, 'calorieFactor');
    setText(_activityFactor, 'activityFactor');
    setText(_proteinCustomWeight, 'proteinCustomWeight');
    setText(_proteinFactor, 'proteinFactor');
    setText(_choPercent, 'choPercent');
    setText(_fibre, 'fibre');
    setText(_waterCustomWeight, 'waterCustomWeight');
    setText(_waterFactor, 'waterFactor');
    setText(_manualWater, 'manualWater');
    setText(_notes, 'notes');
    setState(() {
      _recordId = duplicate ? null : record.id;
      _createdAt = duplicate ? null : record.createdAt;
      _patientId = record.patientId ?? _patientId;
      _gender = Gender.values.byName(data['gender'] as String);
      _diagnoses
        ..clear()
        ..addAll((data['diagnoses'] as List).cast<String>());
      _calorieMethod = CalorieMethod.values.byName(
        data['calorieMethod'] as String,
      );
      _calorieBasis = WeightBasis.values.byName(data['calorieBasis'] as String);
      _proteinBasis = WeightBasis.values.byName(data['proteinBasis'] as String);
      _waterBasis = WeightBasis.values.byName(data['waterBasis'] as String);
      _approved = duplicate ? false : record.approved;
      _step = 2;
    });
  }

  void _reset() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _targetBmi.text = '22.5';
    _calorieFactor.text = '25';
    _activityFactor.text = '1.2';
    _proteinFactor.text = '1.1';
    _choPercent.text = '45';
    _fibre.text = '25';
    _waterFactor.text = '30';
    setState(() {
      _step = 0;
      _gender = null;
      _diagnoses.clear();
      _calorieMethod = CalorieMethod.weightBased;
      _calorieBasis = WeightBasis.actual;
      _proteinBasis = WeightBasis.actual;
      _waterBasis = WeightBasis.actual;
      _approved = false;
      _recordId = null;
      _createdAt = null;
    });
  }

  String get _draftKey => 'patient_${_patientId ?? 'unassigned'}';

  Future<void> _saveDraft() async {
    if (!mounted || _recordId != null) return;
    final hasContent =
        _age.text.isNotEmpty ||
        _height.text.isNotEmpty ||
        _weight.text.isNotEmpty ||
        _notes.text.isNotEmpty;
    if (!hasContent) return;
    await _repository.saveDraft(_draftKey, {
      'patientId': _patientId,
      'age': _age.text,
      'gender': _gender?.name,
      'diagnoses': _diagnoses.toList(),
      'height': _height.text,
      'weight': _weight.text,
      'targetBmi': _targetBmi.text,
      'manualIbw': _manualIbw.text,
      'calorieMethod': _calorieMethod.name,
      'calorieBasis': _calorieBasis.name,
      'calorieCustomWeight': _calorieCustomWeight.text,
      'calorieFactor': _calorieFactor.text,
      'activityFactor': _activityFactor.text,
      'proteinBasis': _proteinBasis.name,
      'proteinCustomWeight': _proteinCustomWeight.text,
      'proteinFactor': _proteinFactor.text,
      'choPercent': _choPercent.text,
      'fibre': _fibre.text,
      'waterBasis': _waterBasis.name,
      'waterCustomWeight': _waterCustomWeight.text,
      'waterFactor': _waterFactor.text,
      'manualWater': _manualWater.text,
      'notes': _notes.text,
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await _repository.loadDraft(_draftKey);
    if (!mounted || draft == null) return;
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore draft?'),
        content: const Text(
          'An unfinished assessment was saved for this patient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (restore == true) {
      _applyValues(draft);
    } else {
      await _repository.deleteDraft(_draftKey);
    }
  }

  Map<String, dynamic> get _presetValues => {
    'targetBmi': _targetBmi.text,
    'calorieMethod': _calorieMethod.name,
    'calorieBasis': _calorieBasis.name,
    'calorieFactor': _calorieFactor.text,
    'activityFactor': _activityFactor.text,
    'proteinBasis': _proteinBasis.name,
    'proteinFactor': _proteinFactor.text,
    'choPercent': _choPercent.text,
    'fibre': _fibre.text,
    'waterBasis': _waterBasis.name,
    'waterFactor': _waterFactor.text,
  };

  void _applyValues(Map<String, dynamic> data) {
    void setText(TextEditingController controller, String key) {
      if (data[key] != null) controller.text = data[key].toString();
    }

    for (final entry in <(TextEditingController, String)>[
      (_age, 'age'),
      (_height, 'height'),
      (_weight, 'weight'),
      (_targetBmi, 'targetBmi'),
      (_manualIbw, 'manualIbw'),
      (_calorieCustomWeight, 'calorieCustomWeight'),
      (_calorieFactor, 'calorieFactor'),
      (_activityFactor, 'activityFactor'),
      (_proteinCustomWeight, 'proteinCustomWeight'),
      (_proteinFactor, 'proteinFactor'),
      (_choPercent, 'choPercent'),
      (_fibre, 'fibre'),
      (_waterCustomWeight, 'waterCustomWeight'),
      (_waterFactor, 'waterFactor'),
      (_manualWater, 'manualWater'),
      (_notes, 'notes'),
    ]) {
      setText(entry.$1, entry.$2);
    }
    setState(() {
      if (data['gender'] != null) {
        _gender = Gender.values.byName(data['gender'] as String);
      }
      if (data['diagnoses'] is List) {
        _diagnoses
          ..clear()
          ..addAll((data['diagnoses'] as List).cast<String>());
      }
      if (data['calorieMethod'] != null) {
        _calorieMethod = CalorieMethod.values.byName(
          data['calorieMethod'] as String,
        );
      }
      if (data['calorieBasis'] != null) {
        _calorieBasis = WeightBasis.values.byName(
          data['calorieBasis'] as String,
        );
      }
      if (data['proteinBasis'] != null) {
        _proteinBasis = WeightBasis.values.byName(
          data['proteinBasis'] as String,
        );
      }
      if (data['waterBasis'] != null) {
        _waterBasis = WeightBasis.values.byName(data['waterBasis'] as String);
      }
      _approved = false;
    });
  }

  Future<void> _openPresets() async {
    var presets = await _repository.presets();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical presets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Presets populate factors only. Dietitian review is still required.',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final preset in presets)
                        ListTile(
                          leading: const Icon(Icons.bookmark_outline),
                          title: Text(preset.name),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _applyValues(preset.values);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _repository.deletePreset(preset.id!);
                              presets = await _repository.presets();
                              setSheetState(() {});
                            },
                          ),
                        ),
                      if (presets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text('No saved presets yet.'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    final name = await _askPresetName(sheetContext);
                    if (name == null || name.trim().isEmpty) return;
                    await _repository.savePreset(
                      AssessmentPreset(
                        name: name.trim(),
                        values: _presetValues,
                      ),
                    );
                    presets = await _repository.presets();
                    setSheetState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Save current factors as preset'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _askPresetName(BuildContext parentContext) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Preset name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4D001A16),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Transform.scale(
        scale: 1.35,
        child: Image.asset(
          'assets/branding/dt_haritha_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    final showLabel = MediaQuery.sizeOf(context).width >= 520;
    return Tooltip(
      message: 'All data stays on this device',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 19, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 10 : 8),
        decoration: BoxDecoration(
          color: const Color(0xFF164F49),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C6D65)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 16,
              color: Color(0xFF8CE0CF),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              const Text(
                'Offline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD7F2ED),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.onChanged});
  final int step;
  final ValueChanged<int> onChanged;
  static const items = [
    (Icons.person_outline, 'Patient'),
    (Icons.monitor_weight_outlined, 'Assessment'),
    (Icons.calculate_outlined, 'Nutrition'),
  ];
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0A3D38),
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26001915),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: step == index
                        ? const Color(0xFFE1F3EF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: step == index
                              ? const Color(0xFF087F6B)
                              : const Color(0xFFF0F4F3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[index].$1,
                          size: 16,
                          color: step == index
                              ? Colors.white
                              : const Color(0xFF6B7C79),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          items[index].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: step == index
                                ? const Color(0xFF075E50)
                                : const Color(0xFF63716F),
                            fontWeight: step == index
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (index < items.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    ),
  );
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.canContinue,
    required this.approved,
    required this.onBack,
    required this.onNext,
    required this.onApprove,
    required this.onSave,
  });
  final int step;
  final bool canContinue;
  final bool approved;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onApprove;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0EAE7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A163A34),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            if (step > 0)
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
            const Spacer(),
            if (step < 2)
              FilledButton.icon(
                onPressed: canContinue ? onNext : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue'),
              )
            else if (!approved)
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review & approve'),
              )
            else
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save assessment'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro(this.eyebrow, this.title, this.subtitle);
  final String eyebrow, title, subtitle;
  @override
  Widget build(BuildContext context) {
    final icon = title.startsWith('Patient')
        ? Icons.person_rounded
        : title.startsWith('Anthropometric')
        ? Icons.straighten_rounded
        : Icons.auto_graph_rounded;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6659), Color(0xFF2A7882)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26065F52),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -55,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC780).withValues(alpha: .12),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        eyebrow,
                        style: const TextStyle(
                          color: Color(0xFFD7F0EB),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFD6E8E5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2EBE9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D173C35),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _sectionIcon(title),
                  size: 19,
                  color: const Color(0xFF087F6B),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 600
        ? Row(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(width: 16),
                Expanded(child: children[index]),
              ],
            ],
          )
        : Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 16),
                children[index],
              ],
            ],
          ),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.integer = false,
    this.optional = false,
    this.min,
    this.max,
  });
  final TextEditingController controller;
  final String label, suffix;
  final bool integer, optional;
  final double? min, max;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final number = double.tryParse(value.text);
          final invalid =
              number != null &&
              ((min != null && number < min!) ||
                  (max != null && number > max!));
          return TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: !integer),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
              ),
            ],
            decoration: InputDecoration(
              labelText: optional ? '$label (optional)' : label,
              suffixText: suffix,
              errorText: invalid
                  ? 'Enter a value from ${min ?? 0} to ${max ?? '∞'}.'
                  : null,
            ),
          );
        },
      );
}

class _FactorField extends StatelessWidget {
  const _FactorField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.presets,
  });
  final TextEditingController controller;
  final String label, suffix;
  final List<double> presets;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _NumberField(
        controller: controller,
        label: label,
        suffix: suffix,
        min: label == 'Activity factor' ? 1 : 0,
        max: switch (label) {
          'Protein factor' => 5,
          'CHO percentage' => 100,
          'Fibre target' => 100,
          'Water factor' => 100,
          'Calorie factor' => 100,
          'Activity factor' => 3,
          _ => null,
        },
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: presets.map((value) {
          final text = value.toString().replaceFirst(RegExp(r'\.0$'), '');
          final selected = controller.text.trim() == text;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: selected ? const Icon(Icons.check_rounded, size: 16) : null,
            label: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF27423D),
                fontWeight: FontWeight.w700,
              ),
            ),
            onSelected: (_) => controller.text = text,
          );
        }).toList(),
      ),
    ],
  );
}

class _BasisPicker extends StatelessWidget {
  const _BasisPicker({
    required this.label,
    required this.value,
    required this.allowIdeal,
    required this.onChanged,
  });
  final String label;
  final WeightBasis value;
  final bool allowIdeal;
  final ValueChanged<WeightBasis> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<WeightBasis>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: WeightBasis.values
        .where((item) => allowIdeal || item != WeightBasis.ideal)
        .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
        .toList(),
    onChanged: (item) {
      if (item != null) onChanged(item);
    },
  );
}

class _Metric {
  const _Metric(this.label, this.value);
  final String label, value;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid(this.metrics);
  final List<_Metric> metrics;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 650 ? 3 : 2;
      final width = (constraints.maxWidth - 12 * (count - 1)) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metrics.indexed
            .map(
              (entry) => SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: entry.$1.isEven
                          ? const [Color(0xFFF0F8F6), Color(0xFFE6F3F0)]
                          : const [Color(0xFFF4F7FA), Color(0xFFEAF1F4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: entry.$1.isEven
                          ? const Color(0xFFD6EAE5)
                          : const Color(0xFFDCE7EB),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .8),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                _metricIcon(entry.$2.label),
                                size: 15,
                                color: entry.$1.isEven
                                    ? const Color(0xFF087F6B)
                                    : const Color(0xFF396B78),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.$2.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF60716E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.$2.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -.2,
                            color: Color(0xFF1A302C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.icon, this.text, {this.error = false});
  final IconData icon;
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final color = error
        ? Theme.of(context).colorScheme.error
        : Colors.orange.shade800;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Equation extends StatelessWidget {
  const _Equation(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    ),
  );
}

class _DiagnosisDialog extends StatefulWidget {
  const _DiagnosisDialog({required this.initial});
  final Set<String> initial;
  @override
  State<_DiagnosisDialog> createState() => _DiagnosisDialogState();
}

class _DiagnosisDialogState extends State<_DiagnosisDialog> {
  late final Set<String> selected = Set.of(widget.initial);
  String query = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select diagnoses'),
    content: SizedBox(
      width: 540,
      height: 480,
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search diagnoses',
            ),
            onChanged: (value) => setState(() => query = value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final group in diagnosisGroups.entries) ...[
                  if (group.value.any(
                    (item) => item.toLowerCase().contains(query),
                  ))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Text(
                        group.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  for (final item in group.value.where(
                    (item) => item.toLowerCase().contains(query),
                  ))
                    CheckboxListTile(
                      value: selected.contains(item),
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (checked) => setState(
                        () => checked == true
                            ? selected.add(item)
                            : selected.remove(item),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, selected),
        child: Text('Apply (${selected.length})'),
      ),
    ],
  );
}

String _format(double? value, String suffix, int decimals) =>
    value == null ? '—' : '${value.toStringAsFixed(decimals)} $suffix';

IconData _sectionIcon(String title) => switch (title) {
  'Patient details' => Icons.badge_outlined,
  'Diagnosis' => Icons.assignment_outlined,
  'Measurements' => Icons.straighten_rounded,
  'Calculated assessment' => Icons.insights_outlined,
  'IBW settings' => Icons.tune_rounded,
  'Energy' => Icons.bolt_rounded,
  'Protein and carbohydrate' => Icons.donut_large_rounded,
  'Fibre and water' => Icons.water_drop_outlined,
  'Clinical notes' => Icons.edit_note_rounded,
  'Assessment summary' => Icons.dashboard_customize_outlined,
  _ => Icons.widgets_outlined,
};

IconData _metricIcon(String label) {
  final value = label.toLowerCase();
  if (value.contains('calorie') || value.contains('energy')) {
    return Icons.local_fire_department_outlined;
  }
  if (value.contains('water')) return Icons.water_drop_outlined;
  if (value.contains('protein')) return Icons.fitness_center_rounded;
  if (value.contains('cho')) return Icons.grain_rounded;
  if (value.contains('fat')) return Icons.opacity_rounded;
  if (value.contains('fibre')) return Icons.grass_rounded;
  if (value.contains('bmi')) return Icons.monitor_weight_outlined;
  if (value.contains('height')) return Icons.height_rounded;
  if (value.contains('weight')) return Icons.scale_outlined;
  return Icons.analytics_outlined;
}
