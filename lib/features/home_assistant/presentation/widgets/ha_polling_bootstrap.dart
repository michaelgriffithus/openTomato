import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ha_providers.dart';

/// The single integration point for the live stream, the foreground poll
/// timer, and the resume backfill. Wraps the app.
class HaPollingBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const HaPollingBootstrap({super.key, required this.child});

  @override
  ConsumerState<HaPollingBootstrap> createState() => _HaPollingBootstrapState();
}

class _HaPollingBootstrapState extends ConsumerState<HaPollingBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(haLiveUpdateServiceProvider.notifier)
            .setForegroundActive(true),
      );
      unawaited(ref.read(haHistoryBackfillServiceProvider).runIfEligible());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      ref.read(haLiveUpdateServiceProvider.notifier).setForegroundActive(false),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final live = ref.read(haLiveUpdateServiceProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(live.setForegroundActive(true));
        unawaited(ref.read(haHistoryBackfillServiceProvider).runIfEligible());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(live.setForegroundActive(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(haPollingServiceProvider);
    return widget.child;
  }
}
