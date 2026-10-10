import 'package:flutter/material.dart';

import '../../data/models/academic_resource.dart';
import '../resources/resource_controller.dart';

/// Revision detail — only uses existing resource fields.
/// No fabricated review dates or intervals (no SRS algorithm exists).
class RevisionDetailScreen extends StatelessWidget {
  final String resourceId;
  const RevisionDetailScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context) {
    final r = ResourceController.instance.resources
        .cast<AcademicResource?>()
        .firstWhere((res) => res?.id == resourceId, orElse: () => null);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revision')),
        body: const Center(child: Text('Not found')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(r.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject: ${r.subjectId ?? "Not linked"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Type: ${r.resourceType.name}'),
            const SizedBox(height: 8),
            Text(
              'Tags: ${r.tags.join(", ")}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'No spaced-repetition schedule is configured. Review this material based on your own study plan.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
