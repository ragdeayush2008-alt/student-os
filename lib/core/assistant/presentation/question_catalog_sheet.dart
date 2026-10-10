import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../question_catalog.dart';
import '../student_assistant_controller.dart';

/// Searchable question catalog for the canonical Assistant.
///
/// Same theme, controller, and state as every other Assistant surface.
/// Tapping a question asks it for real via [StudentAssistantController];
/// guide entries route through the teach-me interception into the
/// Interactive Guide Engine.
class QuestionCatalogSheet extends StatefulWidget {
  const QuestionCatalogSheet({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  static Future<void> show(BuildContext context, {String? categoryId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionCatalogSheet(initialCategoryId: categoryId),
    );
  }

  @override
  State<QuestionCatalogSheet> createState() => _QuestionCatalogSheetState();
}

class _QuestionCatalogSheetState extends State<QuestionCatalogSheet> {
  final _searchCtrl = TextEditingController();
  late String _selectedCategoryId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final origin =
        StudentAssistantController.instance.launchContext.origin;
    _selectedCategoryId = widget.initialCategoryId ??
        QuestionCatalog.preferredCategoryFor(origin);
    if (QuestionCatalog.categories.every((c) => c.id != _selectedCategoryId)) {
      _selectedCategoryId = 'today';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask(CatalogQuestion question) async {
    Navigator.of(context).maybePop();
    await StudentAssistantController.instance.ask(question.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final results = QuestionCatalog.search(_query);
    final searching = _query.trim().isNotEmpty;
    final activeCategory = QuestionCatalog.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => QuestionCatalog.categories.first,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            12,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.sage.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'WHAT CAN I ASK?',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: palette.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore questions',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Search questions',
                textField: true,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search questions…',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!searching) ...[
                _PopularRow(onAsk: _ask),
                const SizedBox(height: 8),
                _RecentRow(onAsk: _ask),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: QuestionCatalog.categories.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = QuestionCatalog.categories[i];
                      final selected = c.id == _selectedCategoryId;
                      return ChoiceChip(
                        label: Text(c.label),
                        selected: selected,
                        onSelected: (_) => setState(
                            () => _selectedCategoryId = c.id),
                        selectedColor: palette.primary,
                        backgroundColor: palette.paleSage.withValues(
                            alpha: palette.isDark ? 0.3 : 0.55),
                        labelStyle: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: selected
                                  ? palette.onPrimary
                                  : palette.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        side: BorderSide(
                          color: selected
                              ? palette.primary
                              : palette.sage.withValues(alpha: 0.4),
                        ),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    if (searching)
                      for (final q in results)
                        _QuestionTile(
                          question: q,
                          onTap: () => _ask(q),
                        ),
                    if (searching && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No matching questions — try "plan", "sleep" or "exam".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: palette.onSurfaceMuted,
                              ),
                        ),
                      ),
                    if (!searching)
                      for (final q in activeCategory.questions)
                        _QuestionTile(
                          question: q,
                          onTap: () => _ask(q),
                        ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Popular starter questions (horizontal chips).
class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.onAsk});

  final Future<void> Function(CatalogQuestion question) onAsk;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POPULAR',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 10,
                color: palette.primary,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QuestionCatalog.popular.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final q = QuestionCatalog.popular[i];
              return ActionChip(
                label: Text(q.prompt),
                onPressed: () => onAsk(q),
                backgroundColor: palette.primary.withValues(alpha: 0.10),
                side: BorderSide(
                  color: palette.primary.withValues(alpha: 0.35),
                ),
                labelStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recent user prompts from persisted history (no duplicate storage).
/// Hidden when there is nothing recent yet.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.onAsk});

  final Future<void> Function(CatalogQuestion question) onAsk;

  @override
  Widget build(BuildContext context) {
    final recent = StudentAssistantController.instance.recentPrompts;
    if (recent.isEmpty) return const SizedBox.shrink();
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          'RECENT',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 10,
                color: palette.primary,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              return ActionChip(
                label: Text(
                  recent[i],
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => onAsk(
                  CatalogQuestion(prompt: recent[i]),
                ),
                backgroundColor:
                    palette.surfaceVariant.withValues(alpha: 0.4),
                side: BorderSide(
                  color: palette.outline.withValues(alpha: 0.6),
                ),
                labelStyle:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.onSurface,
                        ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onTap});

  final CatalogQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final isGuide = question.guideId != null;
    return Semantics(
      button: true,
      label: question.prompt,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: palette.paleSage.withValues(
                  alpha: palette.isDark ? 0.25 : 0.45),
              border: Border.all(
                color: palette.sage.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGuide
                      ? Icons.school_outlined
                      : Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: palette.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“${question.prompt}”',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (question.hint != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          question.hint!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: palette.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
