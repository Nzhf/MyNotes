import 'package:flutter/material.dart';

/// Global key to access the Navigator from outside the widget tree
/// (e.g., from NotificationService)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
