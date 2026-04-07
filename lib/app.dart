import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/audio/stage_audio_controller.dart';
import 'core/presentation/android_fullscreen_scope.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class DoodlelandApp extends ConsumerStatefulWidget {
  const DoodlelandApp({super.key});

  @override
  ConsumerState<DoodlelandApp> createState() => _DoodlelandAppState();
}

class _DoodlelandAppState extends ConsumerState<DoodlelandApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router;
    _router.routerDelegate.addListener(_syncAudioWithRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAudioWithRoute();
    });
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_syncAudioWithRoute);
    super.dispose();
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
