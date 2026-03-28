import 'package:flutter/material.dart';

import 'core/presentation/android_fullscreen_scope.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class DoodlelandApp extends StatelessWidget {
  const DoodlelandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AndroidFullscreenAppScope(
      child: MaterialApp.router(
        title: '그림놀이터',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
