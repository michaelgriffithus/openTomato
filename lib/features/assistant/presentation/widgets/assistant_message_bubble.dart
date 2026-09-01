import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

class AssistantMessageBubble extends StatelessWidget {
  final String role;
  final String content;
  final String? contextBlock;
  final bool streaming;

  const AssistantMessageBubble({
    super.key,
    required this.role,
    required this.content,
    this.contextBlock,
    this.streaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .85),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? palette.heroAccent.withValues(alpha: .18)
                    : palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.cardBorder),
              ),
              child: SelectableText(
                content.isEmpty && streaming ? '…' : content,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: palette.textPrimary),
              ),
            ),
            if (contextBlock != null)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Context sent with this message',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: palette.textSecondary),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.chartSurfaceFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        contextBlock!,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
