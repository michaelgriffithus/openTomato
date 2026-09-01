import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/entry_type.dart';
import '../../domain/helpers/event_type_helper.dart';

Future<EntryType?> showGlobalCaptureSheet(BuildContext context) {
  return showModalBottomSheet<EntryType>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const GlobalCaptureSheet(),
  );
}

Future<void> openGlobalCaptureFlow(BuildContext context) async {
  final type = await showGlobalCaptureSheet(context);
  if (type != null && context.mounted) {
    await context.push(globalCaptureRouteFor(type));
  }
}

String globalCaptureRouteFor(EntryType type) => switch (type) {
      EntryType.stageChange => '/plants/stage-change',
      _ => '/timeline/new?type=${type.storageValue}',
    };

class GlobalCaptureSheet extends StatefulWidget {
  const GlobalCaptureSheet({super.key});

  @override
  State<GlobalCaptureSheet> createState() => _GlobalCaptureSheetState();
}

class _GlobalCaptureSheetState extends State<GlobalCaptureSheet> {
  bool _showMore = false;

  static const _primaryActions = <EntryType>[
    EntryType.watering,
    EntryType.fertilizing,
    EntryType.photo,
    EntryType.inspect,
    EntryType.note,
  ];

  static const _moreActions = <EntryType>[
    EntryType.pruning,
    EntryType.staking,
    EntryType.transplanting,
    EntryType.pest,
    EntryType.disease,
    EntryType.flowering,
    EntryType.harvest,
    EntryType.stageChange,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final actions = _showMore ? _moreActions : _primaryActions;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey('global-capture-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _showMore ? 'MORE' : 'ADD TO JOURNAL',
              style: AppTextStyles.sectionLabel.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _showMore ? 'What else happened?' : 'What happened?',
              style: AppTextStyles.editorialTitle.copyWith(
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 96,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: actions.length + 1,
              itemBuilder: (context, index) {
                if (index == actions.length) {
                  return _CaptureAction(
                    icon: _showMore ? Icons.arrow_back : Icons.more_horiz,
                    label: _showMore ? 'Back' : 'More',
                    color: palette.textSecondary,
                    onTap: () => setState(() => _showMore = !_showMore),
                  );
                }
                final type = actions[index];
                return _CaptureAction(
                  icon: EventTypeHelper.getIcon(type),
                  label: type.displayName,
                  color: EventTypeHelper.getColor(type),
                  onTap: () => Navigator.of(context).pop(type),
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CaptureAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Log $label',
      excludeSemantics: true,
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.24)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
