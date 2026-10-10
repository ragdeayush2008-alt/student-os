import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/academic_resource.dart';
import '../../../data/models/subject.dart';
import '../../subjects/subject_controller.dart';

/// A shared premium tile for browsing an [AcademicResource].
///
/// Used across the Resources command center, search, subject detail and exam
/// study-material sections so every surface stays visually consistent.
class ResourceListTile extends StatelessWidget {
  const ResourceListTile({super.key, required this.resource});

  final AcademicResource resource;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sc = SubjectController.instance;
    final subject = resource.subjectId != null
        ? sc.subjectById(resource.subjectId!)
        : null;

    return AppPressable(
      onTap: () => AppRouter.openResourceDetail(context, resource.id),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                resource.resourceType.icon,
                color: palette.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (resource.description.isNotEmpty ||
                      subject != null ||
                      resource.hasTags)
                    Text(
                      _subtitle(subject),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (resource.isFavorite)
              Icon(
                Icons.star_rounded,
                color: AppColors.streak,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Subject? subject) {
    final parts = <String>[];
    if (subject != null) parts.add(subject.name);
    if (resource.hasTags) parts.add(resource.tags.take(2).join(', '));
    if (resource.description.isNotEmpty && parts.isEmpty) {
      return resource.description;
    }
    return parts.join(' · ');
  }
}
