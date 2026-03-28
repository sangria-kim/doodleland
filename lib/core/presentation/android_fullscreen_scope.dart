import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final NavigatorObserver androidFullscreenNavigatorObserver =
    _AndroidFullscreenNavigatorObserver();

class AndroidFullscreenAppScope extends StatefulWidget {
  const AndroidFullscreenAppScope({super.key, required this.child});

  final Widget child;

  @override
  State<AndroidFullscreenAppScope> createState() =>
      _AndroidFullscreenAppScopeState();
}

class _AndroidFullscreenAppScopeState extends State<AndroidFullscreenAppScope>
    with WidgetsBindingObserver {
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyFullscreenMode();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyFullscreenMode();
    }
  }

  Future<void> _applyFullscreenMode() async {
    if (!_isAndroid) {
      return;
    }

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _AndroidFullscreenNavigatorObserver extends NavigatorObserver {
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _applyFullscreenMode() async {
    if (!_isAndroid) {
      return;
    }

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyFullscreenMode();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyFullscreenMode();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _applyFullscreenMode();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyFullscreenMode();
    super.didRemove(route, previousRoute);
  }
}
