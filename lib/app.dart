import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class DoodlelandApp extends StatelessWidget {
  const DoodlelandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '그림놀이터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
    );
  }
}
