import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCapture,
    required this.reduceMotion,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCapture;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      key: const ValueKey('shell-bottom-tabs-visible'),
      height: 78 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 8,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppColors.blurMedium,
                  sigmaY: AppColors.blurMedium,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.glassSurfaceFill,
                    border: Border(
                      top: BorderSide(color: colors.glassSurfaceBorder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 8,
            bottom: bottomInset,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Destination(
                  index: 0,
                  label: 'Today',
                  icon: Icons.wb_twilight_outlined,
                  selectedIcon: Icons.wb_twilight,
                  selected: selectedIndex == 0,
                  onSelected: onDestinationSelected,
                ),
                _Destination(
                  index: 1,
                  label: 'Timeline',
                  icon: Icons.schedule_outlined,
                  selectedIcon: Icons.schedule,
                  selected: selectedIndex == 1,
                  onSelected: onDestinationSelected,
                ),
                SizedBox(
                  width: 74,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -13),
                      child: _CaptureMedallion(
                        onPressed: onCapture,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ),
                ),
                _Destination(
                  index: 2,
                  label: 'Plants',
                  icon: Icons.local_florist_outlined,
                  selectedIcon: Icons.local_florist,
                  selected: selectedIndex == 2,
                  onSelected: onDestinationSelected,
                ),
                _Destination(
                  index: 3,
                  label: 'Ask',
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  selected: selectedIndex == 3,
                  onSelected: onDestinationSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onSelected,
  });

  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          key: ValueKey('nav-$label'),
          onTap: () => onSelected(index),
          radius: 36,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 50,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.heroAccent.withValues(alpha: .14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 23,
                    color: selected ? colors.heroAccent : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                MediaQuery.withClampedTextScaling(
                  minScaleFactor: 1,
                  maxScaleFactor: 1.2,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTextStyles.labelSmall.copyWith(
                      color:
                          selected ? colors.heroAccent : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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

class _CaptureMedallion extends StatefulWidget {
  const _CaptureMedallion({
    required this.onPressed,
    required this.reduceMotion,
  });

  final VoidCallback onPressed;
  final bool reduceMotion;

  @override
  State<_CaptureMedallion> createState() => _CaptureMedallionState();
}

class _CaptureMedallionState extends State<_CaptureMedallion> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final duration =
        widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 110);
    return Semantics(
      button: true,
      label: 'Log an event',
      child: GestureDetector(
        key: const ValueKey('global-capture-button'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? .94 : 1,
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, .04) : Offset.zero,
            duration: duration,
            curve: Curves.easeOut,
            child: Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0A08F), Color(0xFF7A2418)],
                ),
                border: Border.all(
                  color: colors.heroAccent.withValues(alpha: .75),
                  width: 1.5,
                ),
                boxShadow: _pressed
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .28),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                        BoxShadow(
                          color: const Color(0xFFF0A08F).withValues(alpha: .2),
                          blurRadius: 10,
                          offset: const Offset(-2, -2),
                        ),
                      ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/brand/opentomato-icon.png',
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Align(
                    alignment: const Alignment(-.45, -.55),
                    child: Container(
                      width: 17,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
