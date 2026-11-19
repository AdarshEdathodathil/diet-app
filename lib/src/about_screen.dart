import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Dt Haritha')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      'assets/branding/haritha_profile.jpeg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -.32),
                      semanticLabel: 'Portrait of Dt Haritha E H',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Dt Haritha E H',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clinical Nutritionist & Dietitian',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _CredentialChip(
                              icon: Icons.school_outlined,
                              label: 'M.Sc. Foods and Nutrition',
                            ),
                            _CredentialChip(
                              icon: Icons.school_outlined,
                              label: 'B.Sc. Food Technology',
                            ),
                            _CredentialChip(
                              icon: Icons.workspace_premium_outlined,
                              label: '5+ years of experience',
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Haritha is a clinical nutritionist and dietitian with more than five years of professional experience. She holds a Master of Science in Foods and Nutrition and a Bachelor of Science in Food Technology.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.copyright_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ownership and rights',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SelectableText(
                      'This application, including its content, branding, design, and associated intellectual property, is owned exclusively by Dt Haritha E H. No part may be reproduced, distributed, modified, or used without prior written permission.',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '© 2026 Dt Haritha E H. All rights reserved.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Dt Haritha'),
                subtitle: const Text(
                  'Clinical calculation and documentation aid\nVersion 1.1.0',
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CredentialChip extends StatelessWidget {
  const _CredentialChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
