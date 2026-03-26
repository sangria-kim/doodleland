import 'package:flutter/material.dart';

import 'router/app_router.dart';

class DoodlelandApp extends StatelessWidget {
  const DoodlelandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '그림놀이터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF62B7A5)),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
