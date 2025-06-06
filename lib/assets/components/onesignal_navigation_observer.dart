import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A Navigator observer that reports navigation events to OneSignal for in-app messaging
class OneSignalNavigationObserver extends NavigatorObserver {
  static const String _tag = 'OneSignalNav';
  static const String _defaultRoute = 'Unknown';
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) {
      _sendRouteToOneSignal(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!kIsWeb && newRoute != null) {
      _sendRouteToOneSignal(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb && previousRoute != null) {
      _sendRouteToOneSignal(previousRoute);
    }
  }

  void _sendRouteToOneSignal(Route<dynamic> route) {
    if (kIsWeb) return;

    try {
      final String routeName = _getRouteName(route);
      debugPrint('$_tag: Current route: $routeName');
      OneSignal.InAppMessages.addTrigger('current_page', routeName);
    } catch (e, stackTrace) {
      debugPrint('$_tag Error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  String _getRouteName(Route<dynamic> route) {
    String routeName = _defaultRoute;
    
    try {
      // If the route has a specific name, use it
      if (route.settings.name != null && route.settings.name!.isNotEmpty) {
        return route.settings.name!;
      }

      // Get the type name for unnamed routes
      if (route is MaterialPageRoute) {
        routeName = _getWidgetName(route.builder(navigator!.context));
      } else if (route is CupertinoPageRoute) {
        routeName = _getWidgetName(route.builder(navigator!.context));
      } else if (route is ModalBottomSheetRoute) {
        routeName = 'BottomSheet';
      }
    } catch (e) {
      debugPrint('$_tag Error getting route name: $e');
      routeName = route.settings.toString();
    }

    return routeName;
  }

  String _getWidgetName(Widget widget) {
    return widget.runtimeType.toString();
  }
}
