import 'dart:async';

import 'package:flutter/material.dart';

import 'assessment_repository.dart';
import 'saved_assessment.dart';

class SavedAssessmentsScreen extends StatefulWidget {
  const SavedAssessmentsScreen({super.key, required this.repository});
  final AssessmentRepository repository;

  @override
  State<SavedAssessmentsScreen> createState() => _SavedAssessmentsScreenState();
}

class _SavedAssessmentsScreenState extends State<SavedAssessmentsScreen> {
  final _search = TextEditingController();
  late Future<List<SavedAssessment>> _records = widget.repository.search('');
  Timer? _searchTimer;

  @override
  void dispose() {
    _search.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _runSearch({bool immediate = false}) {
    _searchTimer?.cancel();
    if (immediate) {
      setState(() => _records = widget.repository.search(_search.text));
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _records = widget.repository.search(_search.text));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved assessments',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            'Private records stored on this device',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFB9D8D2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F3EF), Color(0xFFF2F7F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1E7E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.folder_special_outlined,
                        color: Color(0xFF087F6B),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Assessment library',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => _runSearch(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search diagnosis, age, gender or ID',
                      fillColor: Colors.white,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                _runSearch(immediate: true);
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SavedAssessment>>(
                future: _records,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const _EmptyState(
                      Icons.error_outline,
                      'Could not open the local assessment database.',
                    );
                  }
                  final records = snapshot.data ?? [];
                  if (records.isEmpty) {
                    return const _EmptyState(
                      Icons.folder_open_outlined,
                      'No saved assessments found.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE0EAE8)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D173C35),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context, record),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF15937C),
                                        Color(0xFF2F6E79),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${record.id}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${record.age} years · ${record.gender}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2F4EA),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Approved',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF227247),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        record.diagnoses.join(', '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF536461),
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 5,
                                        children: [
                                          _Meta(
                                            Icons.calendar_today_outlined,
                                            _date(record.updatedAt),
                                          ),
                                          _Meta(
                                            Icons.monitor_weight_outlined,
                                            'BMI ${record.bmi?.toStringAsFixed(2) ?? '—'}',
                                          ),
                                          _Meta(
                                            Icons
                                                .local_fire_department_outlined,
                                            '${record.calories?.toStringAsFixed(0) ?? '—'} kcal',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF6E817E),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF748481)),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF748481),
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.icon, this.message);
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

String _date(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}
