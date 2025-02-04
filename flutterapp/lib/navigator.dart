import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MyNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void pushNamed(String routeName) {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }
}
