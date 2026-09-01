import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final Set<String> _pendingPushLocations = <String>{};

extension AppRouterExtensions on BuildContext {
  Future<T?> pushDeduped<T extends Object?>(String location) async {
    final router = GoRouter.of(this);
    final currentLocation =
        router.routeInformationProvider.value.uri.toString();

    if (currentLocation == location ||
        _pendingPushLocations.contains(location)) {
      return null;
    }

    _pendingPushLocations.add(location);
    try {
      return await push<T>(location);
    } finally {
      _pendingPushLocations.remove(location);
    }
  }
}
