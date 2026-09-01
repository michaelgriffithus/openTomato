import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_navigation.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final VoidCallback onCapture;

  const AppScaffold({
    super.key,
    required this.navigationShell,
    required this.onCapture,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AnimatedSwitcher(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: !keyboardVisible
            ? AppBottomNavigation(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onDestinationSelected,
                onCapture: onCapture,
                reduceMotion: reduceMotion,
              )
            : const SizedBox(key: ValueKey('shell-bottom-tabs-hidden')),
      ),
    );
  }
}
