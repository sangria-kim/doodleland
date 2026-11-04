import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/audio/stage_audio_controller.dart';
import 'core/presentation/android_fullscreen_scope.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/presentation/settings_viewmodel.dart';
import 'router/app_router.dart';

class DoodlelandApp extends ConsumerStatefulWidget {
  const DoodlelandApp({super.key});

  @override
  ConsumerState<DoodlelandApp> createState() => _DoodlelandAppState();
}

class _DoodlelandAppState extends ConsumerState<DoodlelandApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router;
    ref.listenManual(
      settingsViewModelProvider.select((state) => state.settings),
      (_, settings) {
        unawaited(
          ref.read(stageAudioControllerProvider).applySettings(settings),
        );
      },
      fireImmediately: true,
    );
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    unawaited(
      ref
          .read(stageAudioControllerProvider)
          .setForeground(
            lifecycle == null || lifecycle == AppLifecycleState.resumed,
          ),
    );
    _router.routerDelegate.addListener(_syncAudioWithRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAudioWithRoute();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_syncAudioWithRoute);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref
          .read(stageAudioControllerProvider)
          .setForeground(state == AppLifecycleState.resumed),
    );
  }

  void _syncAudioWithRoute() {
    if (!mounted) {
      return;
    }
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    unawaited(ref.read(stageAudioControllerProvider).syncRoutePath(path));
  }

  @override
  Widget build(BuildContext context) {
    return AndroidFullscreenAppScope(
      child: MaterialApp.router(
        title: '그림놀이터',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
